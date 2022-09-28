import argparse
import tempfile
import sqlite3
import os
import pathlib
import webbrowser
from datetime import datetime
from prettytable import PrettyTable


DEFAULT_REPORT_PATH = "/work2/common/valid_ethernet/acceptance_data"
STR_TIME_FORMAT = "%Y-%m-%d_%H-%M-%S"


def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d


def get_or_create(con, cur, table, **kwargs):
    while True:
        sql = f"SELECT id FROM {table} WHERE " \
            + " AND ".join([f"`{x}` = '{y}'" for x, y in kwargs.items() if y is not None])
        cur.execute(sql)
        id = cur.fetchone()
        if id is not None:
            return id['id']
        else:
            k = ",".join([f'`{x}`' for x,y in kwargs.items() if y is not None])
            v = ",".join([f"'{x}'" for x in kwargs.values() if x is not None])
            cur.execute(f"INSERT INTO {table} ({k}) VALUES ({v})")
            con.commit()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--from-db', help='Path to the acceptance Sqlite database to merge from', required=True)
    parser.add_argument('-i', '--into-db', help='Path to the acceptance Sqlite database to merge into', required=True)
    parser.add_argument('-q', '--quiet', help="Do not ask before merging each acceptance run", action='store_true')
    parser.add_argument('-p', '--report-path', help="Location where pytest reports are stored", default=DEFAULT_REPORT_PATH)
    parser.add_argument('-r', '--release', help='Linux release. e.g. 4.8', default="None")
    parser.add_argument('-n', '--no-skip', help='Do not skip acceptance tests with the same timestamp in both DB', action='store_true')
    args = parser.parse_args()

    html_report_path = f"{args.report_path}/release-{args.release}" 
    
    # check db file
    if not os.path.isfile(args.from_db):
        raise Exception(f"ERROR: {args.from_db} is not a file")
    if not os.path.isfile(args.into_db):
        raise Exception(f"ERROR: {args.into_db} is not a file")

    # connect to database
    con_from = sqlite3.connect(args.from_db)
    con_from.row_factory = dict_factory
    cur_from = con_from.cursor()
    con_into = sqlite3.connect(args.into_db)
    con_into.row_factory = dict_factory
    cur_into = con_into.cursor()
    
    # get all test timestamps from "into-db" to avoid merging twice the same test runs
    # warning: we suppose that the user runs the script until the end because all timestamps 
    # from "from-db" are added into "into-db" in next paragraph
    into_timestamps = []
    for row in cur_into.execute(f"SELECT date_time FROM acceptance_test"):
        into_timestamps.append(row['date_time'])
    
    # mapping of objects between both databases
    obj_map = {}
    for table in ['eth_cable', 'eth_cable_sn', 'k200', 'link_partner', 'acceptance_test', 'test_scenario_param', 'testcase_result']:
        obj_map[table] = {}
        for row in cur_from.execute(f"SELECT * FROM {table}"):
            from_id = row['id']
            del row['id']
            into_id = get_or_create(con_into, cur_into, table, **row)
            obj_map[table][from_id] = into_id
    
    obj_map['acceptance_config'] = {}
    for row in cur_from.execute("SELECT * from acceptance_config"):
        from_id = row['id']
        del row['id']
        into_id = get_or_create(con_into, cur_into, 'acceptance_config', k200=obj_map['k200'][row['k200']],
                                link_partner=obj_map['link_partner'][row['link_partner']], 
                                cable=obj_map['eth_cable'][row['cable']])
        obj_map['acceptance_config'][from_id] = into_id
    
    # get max id in table acceptance_run
    sql = "SELECT id FROM acceptance_run ORDER BY id DESC LIMIT 1"
    cur_into.execute(sql)
    into_id = cur_into.fetchone()['id'] + 1
    
    nb_tests = 0
    prev_dt = None
    obj_map['acceptance_run'] = {}
    cur_from.execute("SELECT * from acceptance_run")
    all_runs = cur_from.fetchall()
    for row in all_runs:
        ans = ""
        if not args.quiet:
            dt = cur_from.execute(f"SELECT date_time FROM acceptance_test WHERE id = {row['test']}").fetchone()
            
            if not args.no_skip and dt['date_time'] in into_timestamps:
                print(f"Test with timestamp {dt['date_time']} was already merged. Skipped")
                continue
            
            print(f"Test timestamp: {dt['date_time']}")
            
            # open HTML report in web browser
            date_time = datetime.strptime(dt['date_time'], '%Y-%m-%d %H:%M:%S.%f').strftime(STR_TIME_FORMAT)
            # avoid opening multiple times the same report
            if prev_dt is None or date_time != prev_dt:
                print(f"report URL: file://{html_report_path}/{date_time}/report.html")
                webbrowser.open(f"file://{html_report_path}/{date_time}/report.html")
                prev_dt = date_time

                # print test results in terminal
                pretty_results = PrettyTable()
                with open(f"{html_report_path}/{date_time}/stats.csv", "r") as f:
                    f.readline()
                    pretty_results.field_names = f.readline().split(',')
                    for r in f.readlines():
                        pretty_results.add_row(r.split(','))
                print(pretty_results)
            
            print(f"MPPA interface: {row['mppa_interface']}")
            print("Run params:")
            for row2 in cur_from.execute(f"SELECT name,value FROM test_scenario_param t JOIN run_tsparam r ON t.id = r.tsp WHERE r.run = {row['id']}"):
                print(f"\t- {row2['name']}= {row2['value']}")
            
            while ans not in ['y', 'n']:
                ans = input(f"Do you want to merge run {row['id']}? (y/n)")
        
        from_id = row['id']
        row['id'] = into_id
        row['test'] = obj_map['acceptance_test'][row['test']]
        row['config'] = obj_map['acceptance_config'][row['config']]
        row['cable_sn'] = obj_map['eth_cable_sn'][row['cable_sn']]
        
        if args.quiet or ans == 'y':
            get_or_create(con_into, cur_into, "acceptance_run", **row)
            print(f"[+] Run {from_id} was merged. New id: {into_id}\n")
            nb_tests += 1
            obj_map['acceptance_run'][from_id] = into_id
            into_id += 1
    
    # merge many-to-many tables
    for row in cur_from.execute("SELECT * from run_tcresult"):
        del row['id']
        if row['run'] in obj_map['acceptance_run']:
            row['run'] = obj_map['acceptance_run'][row['run']]
            row['tcr'] = obj_map['testcase_result'][row['tcr']]
            get_or_create(con_into, cur_into, 'run_tcresult', **row)
    for row in cur_from.execute("SELECT * from run_tsparam"):
        del row['id']
        if row['run'] in obj_map['acceptance_run']:
            row['run'] = obj_map['acceptance_run'][row['run']]
            row['tsp'] = obj_map['test_scenario_param'][row['tsp']]
        get_or_create(con_into, cur_into, 'run_tsparam', **row)
    
    print(f"[+] Done. {nb_tests}/{len(all_runs)} test runs were merged from {args.from_db} to {args.into_db}.")
