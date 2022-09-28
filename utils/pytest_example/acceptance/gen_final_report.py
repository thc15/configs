import argparse
import tempfile
import sqlite3
import os
import pathlib
from datetime import datetime
import pandas as pd
import numpy as np
import math


STR_TIME_FORMAT = "%Y-%m-%d_%H-%M-%S"

DIR = pathlib.Path(__file__).parent.absolute()

EMPTY_CIRCLE = "{icon circle-o color=black}"

PERF_THRESHOLDS = {
    'supported': (100, "green"),
    'good': (90, "yellow"),
    'acceptable': (50, "orange"),
    'bad': (0, "red"),
}

DIFF_COLORS = {
    '+100%': (100, 'blue'),
    'improvement': (10, 'green'),
    'stable': (0, 'black'),
    'minor regression': (-10, 'yellow'),
    'regression': (-50, 'orange'),
    'not working anymore': (-100, 'red')
}

# useful to always maintain the same order inside tables
ALL_TEST_CASES = ['EEPROM read', 'Link up at boot', 'Force link up', 'Speed test', 'Simple ping', 'Iperf3 RX', 'Iperf3 TX']

# we don't want to take 'Force link up' into account when computing scores
SCORE_TEST_CASES = ['EEPROM read', 'Link up at boot', 'Speed test', 'Simple ping', 'Iperf3 RX', 'Iperf3 TX']

TEST_PARAMS = [] # test parameters - will be filled later

# what we want to show in the report
NICE_HEADERS = {
    'k200_sn': 'K200 SN', 'k200_config': 'K200 Config', 'k200_type': 'K200 Type', 'mppa_interface': 'MPPA Interface',
    'lpg_name': 'Link Partner', 'lp_type': 'LP Type', 'cab_vendor': 'Cable Vendor', 'cab_type': 'Cable Type',
    'cab_pn': 'Cable PN'
}


def perf_color_circle(a):
    if math.isnan(a):
        return EMPTY_CIRCLE
    for thres in PERF_THRESHOLDS.values():
        if int(a) >= thres[0]:
            return f"{{icon circle  color={thres[1]}}}"
    return f"{{icon circle  color={PERF_THRESHOLDS['bad'][1]}}}"


def diff_color_percent(pt):
    if math.isnan(pt):
        return EMPTY_CIRCLE
    color = [z for _,(y,z) in DIFF_COLORS.items() if pt >= y][0]
    return f"{{icon circle  color={color}}}"


def nice_speed(speed_str):
    speeds = speed_str.split(',')
    if speeds[0].split('=')[1] == speeds[1].split('=')[1]:
        sp = int(speeds[0].split('=')[1])
        if sp % 1000 == 0:
            return "%dG" % int(sp / 1000)
        return str(sp)
    return speed_str


def dict_to_str(obj):
    """ convert dict object to readable string"""
    if isinstance(obj, dict):
        return " ".join([f"{x}:{obj[x]}" for x in sorted(obj)])
    return str(obj)


def list_intersection(list1, list2):
    return [x for x in list1 if x in list2]


def phab_link(date_time):
    date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f').strftime(STR_TIME_FORMAT)
    return f"[[file:///{args.data}/release-{args.release}/{date_time}/|path]]"


def phab_remarkup_table(data, columns=None, col_split=[], show_index=False):
    """ Generate a table for Phabricator from dataframe provided. The table can be split
        in multiple tables using col_split argument. Only the columns in `columns` will be shown.
    """
    data = data.copy()
    if columns is None:
        columns = data.columns
    out = ""
    if col_split:
        data.sort_values(by=col_split, inplace=True)
        grouped_df = data.groupby(col_split)
        for params, gdf in grouped_df:
            out += "- " + "   ".join([f"{x}={y}" for x,y in zip(col_split, params)]) + "\n\n"
            for col in col_split:
                del gdf[col]
            out += gdf[columns].to_markdown(index=show_index) + '\n\n'
    else:
        out += data[columns].to_markdown(index=show_index)
    return out.replace('|:', '|-').replace(':|', '-|')


def get_all_test_run(release, run_tsparam):
    """ Returns a Dataframe containing all the test runs in the DB, their parameters (autoneg, speed...) as dict,
        and the results of the test cases.
    """
    # get all test runs frm DB
    sql_req = ("SELECT run.id AS run_id, date_time, mppa_interface, k200.id AS k200_id, k200.type AS k200_type, k200.sn AS k200_sn, "
            "k200.config AS k200_config, lpg.id AS lpg_id, lpg.name AS lpg_name, lp.type AS lp_type, cab.id AS cab_id, "
            "cab.vendor AS cab_vendor, cab.type AS cab_type, cab.pn AS cab_pn, run.cable_sn AS cab_sn_id, cab_sn.sn AS cab_sn "
            "FROM acceptance_run run "
            "JOIN acceptance_test test ON run.test = test.id "
            "JOIN acceptance_config conf ON run.config = conf.id "
            "JOIN k200 ON conf.k200 = k200.id "
            "JOIN link_partner lp ON link_partner = lp.id "
            "JOIN lp_groups lpg ON lp.`group` = lpg.id "
            "JOIN eth_cable cab ON conf.cable = cab.id "
            "JOIN eth_cable_sn cab_sn ON run.cable_sn = cab_sn.id "
            "WHERE linux_release = ?"
            )
    all_test_runs = pd.read_sql_query(sql_req, con=con, params=(release,), index_col='run_id')
    if all_test_runs.empty:
        return None
    for i,p in enumerate(TEST_PARAMS):
        all_test_runs.insert(i, p, "Nan")
        for x in all_test_runs.index:
            if p in run_tsparam[x]:
                all_test_runs.at[x, p] = dict_to_str(run_tsparam[x][p])
    
    # if autoneg is ON and FEC is Nan, we change it to auto
    all_test_runs.loc[all_test_runs['autoneg'] == 'on', 'fec'] = 'auto'
    
    # test cases results
    cur.execute("SELECT run,label,success,total FROM run_tcresult r JOIN testcase_result t ON t.id = r.tcr")
    for row in cur.fetchall():
        if row[0] not in all_test_runs.index:
            continue
        all_test_runs.at[row[0], row[1] + '__success'] = row[2]
        all_test_runs.at[row[0], row[1] + '__total'] = row[3]
        all_test_runs.at[row[0], row[1]] = f"{row[2]}/{row[3]}"
        all_test_runs.at[row[0], row[1] + '__percent'] = row[2] / row[3] * 100
    
    # add path to html report of each test run
    all_test_runs['Path'] = [phab_link(dt) for dt in all_test_runs['date_time']]
    
    return all_test_runs


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--acceptance-db', help='Path to the acceptance Sqlite database', required=True)
    parser.add_argument('-f', '--data', help='Path of the root where all the data, logs etc is stored', required=True)
    parser.add_argument('-r', '--release', help='Linux release. e.g. 4.6', required=True)
    parser.add_argument('-p', '--previous-release', help='previous Linux release to compare with. e.g. 4.5', required=True)
    parser.add_argument('-w', '--preliminary', action='store_true', help='add warning for preliminary report')
    args = parser.parse_args()
    
    # check db file and data dir exits
    if not os.path.isdir(args.data):
        raise Exception(f"ERROR: {args.data} is not a directory")
    if not os.path.isfile(args.acceptance_db):
        raise Exception(f"ERROR: {args.acceptance_db} is not a file")

    # connect to database
    con = sqlite3.connect(args.acceptance_db)
    cur = con.cursor()
    
    # all the data for the report has to be added in 'report_data'
    report_data = {'release': args.release, 'previous_release': args.previous_release}
    if args.preliminary:
        now = datetime.strftime(datetime.now(), '%Y-%m-%d %H:%M')
        report_data['warning'] = f"WARNING: this is a preliminary report generated on {now}. The acceptance is still in progress."
    else:
        report_data['warning'] = ""
    
    # get all test parameters (autoneg, speed...) from DB
    run_tsparam = {}
    cur.execute("SELECT name,value FROM test_scenario_param")
    all_tsp = cur.fetchall()
    for row in cur.execute("SELECT rt.run,p.id,p.name,p.value FROM run_tsparam rt JOIN test_scenario_param p ON tsp = p.id"):
        run_tsparam.setdefault(row[0], {})
        if row[2] == 'speed':
            # for readability, we simplify the speed: 'host=100000,mppa=100000' -> 100G
            run_tsparam[row[0]][row[2]] = nice_speed(row[3])
        else:
            run_tsparam[row[0]][row[2]] = row[3]
        if row[2] not in TEST_PARAMS:
            TEST_PARAMS.append(row[2])
    
    # all test runs for the current release
    all_test_runs = get_all_test_run(args.release, run_tsparam)
    
    # select the configuration (lp, cable) that has been tested with the max number of k200
    sql_req = ("SELECT lp.`group`, lp.type, lp.description, cab.id, cab.vendor, cab.pn, "
               "COUNT(DISTINCT(k200)) ck FROM acceptance_test test "
               "JOIN acceptance_run run ON run.test = test.id "
               "JOIN acceptance_config conf ON run.config = conf.id "
               "JOIN k200 ON conf.k200 = k200.id "
               "JOIN link_partner lp ON conf.link_partner = lp.id "
               "JOIN eth_cable cab ON conf.cable = cab.id "
               "WHERE linux_release = ? "
               "GROUP BY lp.`group`, cab.id "
               "ORDER BY ck DESC LIMIT 1"
               )
    cur.execute(sql_req, (args.release,))
    lp_group_id, lp_type, report_data['0_lp_desc'], cable_id, report_data['0_cable_vendor'], report_data['0_cable_pn'], _ = cur.fetchone()
    report_data['0_lp_type'] = lp_type

    # get all test runs with the configuration found above
    df = all_test_runs[(all_test_runs['lpg_id'] == lp_group_id) & (all_test_runs['cab_id'] == cable_id)].copy()
    tc_df = list_intersection(ALL_TEST_CASES, df.columns)
    table_headers = ['k200_type', 'k200_sn', 'k200_config', 'mppa_interface'] + tc_df + ['Path']
    report_data['0_bunch_k200'] = phab_remarkup_table(df, table_headers, col_split=TEST_PARAMS)

    # compute the 'total' table
    table_headers = TEST_PARAMS + tc_df
    for tc in tc_df:
        df[tc] = df[tc + '__percent']
    totals = df.groupby(TEST_PARAMS, as_index=False).mean()
    report_data['0_totals'] = phab_remarkup_table(totals, table_headers)

    # select the k200 that was the most tested
    sql_req = ("SELECT k200.id, k200.type, k200.config, k200.sn, COUNT(k200.id) kc "
               "FROM acceptance_test test "
               "JOIN acceptance_run run ON run.test = test.id "
               "JOIN acceptance_config conf ON run.config = conf.id "
               "JOIN k200 ON conf.k200 = k200.id "
               "WHERE linux_release = ? "
               "GROUP BY k200.id "
               "ORDER BY kc DESC LIMIT 1"
               )
    cur.execute(sql_req, (args.release,))
    k200_id, report_data['1_k200_type'], report_data['1_k200_config'], report_data['1_k200_sn'], _ = cur.fetchone()
   
    # get all the test runs with the k200 found above
    df = all_test_runs[all_test_runs['k200_id'] == k200_id]
    table_headers = ['mppa_interface', 'lpg_name', 'lp_type', 'cab_vendor', 'cab_type', 'cab_pn'] + list_intersection(ALL_TEST_CASES, df.columns) + ['Path']
    report_data['1_single_k200'] = phab_remarkup_table(df, table_headers, col_split=TEST_PARAMS)
    
    # mapping of color and score range
    report_data["2_perf_color"] = []
    for label, thres in PERF_THRESHOLDS.items():
        line = '|%s|' % '|'.join([f"{{icon circle  color={thres[1]}}}", label] + [f">={thres[0]}"])
        report_data["2_perf_color"].append(line)
    report_data["2_perf_color"].append(f"| {EMPTY_CIRCLE} | no data | / |")
    
    # compute a score for each setup and each set of parameters (autoneg, speed) which will be 
    # represented by a colored-bullet
    # score = min(test1_percentage, test2_percentage, ...)
    cols = ['lpg_name', 'lp_type', 'cab_vendor', 'cab_type', 'cab_pn']
    min_table = pd.DataFrame(columns=cols, data=all_test_runs)
    min_table = min_table.groupby(cols, as_index=True).min()
    groupby_df = all_test_runs.groupby(TEST_PARAMS)
    for params, gdf in groupby_df:
        gdf = gdf.groupby(cols, as_index=True)
        gdf = gdf[[f'{x}__percent' for x in ALL_TEST_CASES]].min()
        min_table[params] = gdf.apply(lambda x: " ".join(x.astype(str)), axis=1)
    color_table = min_table.copy()
    for col in groupby_df.indices.keys():
        c = []
        for x in color_table[col]:
            if str(x) == 'nan':
                c.append(EMPTY_CIRCLE)
            else:
                c.append(" ".join([perf_color_circle(np.float(y)) for y in x.split(' ')]))
        color_table[col] = c
    color_table.reset_index(inplace=True)
    report_data["3_summary"] = phab_remarkup_table(color_table)
    report_data["3_parameters"] = ", ".join(TEST_PARAMS)
    report_data["3_all_tests"] = ", ".join(ALL_TEST_CASES)

    # here we build a "light" version of the full summary
    # first icon: max(link up at boot, force link up)
    # second icon: min(simple ping, iperf rx, iperf tx)
    def minimalist_map(x):
        if str(x) == 'nan':
            return EMPTY_CIRCLE
        # 0: eeprom, 1: link boot, 2: force link, 3: speed, 4: ping, 5: iperf RX, 6: iperf TX
        pt = [np.float(y) for y in x.split(' ')]
        return perf_color_circle(max(pt[1], pt[2])) + " " + perf_color_circle(min(pt[4], pt[5], pt[6]))
    
    color_table = min_table.copy()
    color_table = color_table[[x for x in color_table.columns if x[0] == 'on']] # we show only autoneg columns
    color_table = color_table.applymap(minimalist_map)
    color_table.reset_index(inplace=True)
    report_data["9_light_summary"] = phab_remarkup_table(color_table)
    
    # difference between enmppa0 and enmppa4
    # 1 colored-bullet for each test case and set of parameters
    # 1 bullet = minimum score of all test runs
    df = all_test_runs.groupby(cols + ['mppa_interface'] + TEST_PARAMS, sort=True).mean()
    color_table = {}
    all_param_sets = set()
    report_data["7_legend_icons"] = []
    for idx, data in df.iterrows():
        i = idx[:len(cols)]
        itf_params = idx[len(cols):]
        all_param_sets.add(itf_params[1:])
        color_table.setdefault(i, {})
        color_table[i].setdefault(itf_params[0], {})
        color_table[i][itf_params[0]][itf_params[1:]] = data[[f'{x}__percent' for x in SCORE_TEST_CASES]].min()
    ct_df = pd.DataFrame(columns=cols + ['enmppa0', 'enmppa4'])
    for idx, data1 in color_table.items():
        el = {x:y for x,y in zip(cols, idx)}
        for itf, data2 in data1.items():
            el[itf] = " ".join([perf_color_circle(data2[x]) if x in data2 else EMPTY_CIRCLE for x in all_param_sets])
        ct_df = ct_df.append(el, ignore_index=True)
    report_data["7_legend_icons"] = '- ({}): {}'.format(", ".join(TEST_PARAMS), ", ".join([str(x) for x in all_param_sets]))
    report_data["7_diff_enmppa0_4"] = phab_remarkup_table(ct_df)

    # difference between k200_rev2 and k200lp_rev1
    # 1 colored-bullet for each test case and set of parameters
    # 1 bullet = minimum score of all test runs
    all_param_sets.clear()
    df = all_test_runs.groupby(cols + ['k200_type'] + TEST_PARAMS, sort=True).mean()
    color_table = {}
    all_param_sets = set()
    all_k200_types = set()
    for idx, data in df.iterrows():
        i = idx[:len(cols)]
        k200_params = idx[len(cols):]
        all_param_sets.add(k200_params[1:])
        all_k200_types.add(k200_params[0])
        color_table.setdefault(i, {})
        color_table[i].setdefault(k200_params[0], {})
        color_table[i][k200_params[0]][k200_params[1:]] = data[[f'{x}__percent' for x in SCORE_TEST_CASES]].min()
    ct_df = pd.DataFrame(columns=cols + list(all_k200_types))
    for idx, data1 in color_table.items():
        el = {x:y for x,y in zip(cols, idx)}
        for k200_type, data2 in data1.items():
            el[k200_type] = " ".join([perf_color_circle(data2[x]) if x in data2 else EMPTY_CIRCLE for x in all_param_sets])
        ct_df = ct_df.append(el, ignore_index=True)
    report_data["8_legend_icons"] = '- ({}): {}'.format(", ".join(TEST_PARAMS), ", ".join([str(x) for x in all_param_sets]))
    report_data["8_diff_board_types"] = phab_remarkup_table(ct_df)
    
    # generate diff/color table
    report_data["6_diff_color"] = []
    for label, (thres, color) in DIFF_COLORS.items():
        line = '|%s|' % '|'.join([f"{{icon circle  color={color}}}", label, f">={thres}%"])
        report_data["6_diff_color"].append(line)
    report_data["6_diff_color"].append(f"| {EMPTY_CIRCLE} | no data | / |")
    
    # comparison table with previous release   
    # 1 colored-bullet for each test case and set of parameters
    # 1 bullet = mean(score of all test runs of current release) - mean(score of all test runs of previous release)
    diff_table = pd.DataFrame(columns=cols, data=all_test_runs)
    all_test_runs_prev = get_all_test_run(args.previous_release, run_tsparam)
    df = all_test_runs.groupby(cols + TEST_PARAMS).mean() - all_test_runs_prev.groupby(cols + TEST_PARAMS).mean()
    color_table = {}
    all_param_sets = set()
    for idx, data in df.iterrows():
        setup = idx[:len(cols)]
        params = idx[len(cols):]
        all_param_sets.add(params)
        color_table.setdefault(setup, {})
        color_table[setup][params] = " ".join([diff_color_percent(data[f'{x}__percent']) for x in SCORE_TEST_CASES])
    ct_df = pd.DataFrame(columns=cols + list(all_param_sets))
    for idx, data1 in color_table.items():
        el = {x:y for x,y in zip(cols, idx)}
        for params, data2 in data1.items():
            el[params] = data2
        ct_df = ct_df.append(el, ignore_index=True)
    
    # remove empty columns from the comparison table (nan and/or empty bullets)
    for col in ct_df.columns:
        all_values = ''.join([str(x) for x in ct_df[col]])
        all_values = all_values.replace('nan', '').replace(EMPTY_CIRCLE, '').strip()
        if all_values == '':
            ct_df.drop(col, inplace=True, axis=1)

    report_data["4_comparison"] = phab_remarkup_table(ct_df)
    report_data["4_tests_name"] = ", ".join(SCORE_TEST_CASES)
    report_data["4_parameters"] = ", ".join(TEST_PARAMS)
    
    # table of link to all html reports
    sql_req = ("SELECT run.id, date_time, k200.type, lpg.name, lp.type, cab.vendor, cab.type, cab.pn "
               "FROM acceptance_run run "
               "CROSS JOIN acceptance_test test ON run.test = test.id "
               "JOIN acceptance_config conf ON run.config = conf.id "
               "JOIN link_partner lp ON conf.link_partner = lp.id "
               "JOIN lp_groups lpg ON lp.`group` = lpg.id "
               "JOIN eth_cable cab ON conf.cable = cab.id "
               "JOIN k200 ON k200.id = conf.k200 "
               "WHERE linux_release = ? "
               "ORDER BY date_time ASC"
               )
    report_data["5_all_reports"] = []
    already_done = []
    for row in cur.execute(sql_req, (args.release,)):
        if row[0] in already_done:
            continue
        already_done.append(row[0])
        date_time = datetime.strptime(row[1], '%Y-%m-%d %H:%M:%S.%f')
        line = "|%s|" % '|'.join([
            *row[2:],
            f"[[file:///{args.data}/release-{args.release}/{date_time.strftime(STR_TIME_FORMAT)}/report.html|path]]"
        ])
        report_data["5_all_reports"].append(line)
    
    # generate Phab report
    for k, v in report_data.items():
        if type(v) == list:
            report_data[k] = '\n'.join(v)
    with open(os.path.join(DIR, 'report_template.txt'), 'r') as f:
        report_txt = f.readlines()
        report_txt = ''.join(report_txt)
    report_txt = report_txt.format(**report_data)
    for search, subst in NICE_HEADERS.items():
        report_txt = report_txt.replace(search, subst)
    
    # write report to a temporary file
    fd, report_path = tempfile.mkstemp()
    with os.fdopen(fd, 'w') as f:
            f.write(report_txt)
    
    print(f"[+] Final report was generated successfully : {report_path}")
