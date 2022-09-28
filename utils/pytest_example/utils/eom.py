import struct
import tempfile
import base64
from io import BytesIO
from PIL import Image, ImageFilter


class EOM:
    
    RTM = {
        'RX': '/sys/bus/i2c/drivers/ti-retimer/3-0018',
        'TX': '/sys/bus/i2c/drivers/ti-retimer/3-0019'
    }
    SIZE = (64, 64)
    IMG_SEP = 10
    
    def __init__(self, remote, lanes=range(8), mode='RX'):
        self.remote = remote
        assert mode in ['RX', 'TX'], "incorrect EOM mode: must be 'TX' or 'RX'"
        self.mode = mode
        self.rtm = EOM.RTM[mode]
        assert all([x >= 0 and x <= 8 for x in lanes]), "Incorrect EOM lane"
        self.lanes = lanes
    
    def set_swing(self, itf, swing=24):
        itf.sysfs.phy.param[:].swing = swing
    
    def draw_eom(self):
        mppa_feom = "/tmp/eom_hit_cnt"
        imgs = {}
        _, feom = tempfile.mkstemp()
        for i in self.lanes:
            self.remote.run_cmd(f"cat {self.rtm}/eom/{i}/eom_hit_cnt > {mppa_feom}", expect_ret=0)
            self.remote.get(mppa_feom, feom)
            imgs[i] = EOM._data2img(feom)
        img = Image.new(mode="RGB", size=(3*EOM.SIZE[0], len(self.lanes)*(EOM.SIZE[1]+EOM.IMG_SEP)))
        for i in self.lanes:
            img.paste(imgs[i][0], (0, i*(EOM.SIZE[1]+EOM.IMG_SEP)))
            img.paste(imgs[i][1], (EOM.SIZE[0], i*(EOM.SIZE[1]+EOM.IMG_SEP)))
            img.paste(imgs[i][2], (2*EOM.SIZE[0], i*(EOM.SIZE[1]+EOM.IMG_SEP)))
            for j in range(3):
                imgs[i][j].close()
        im = img.resize((2*img.size[0], 2*img.size[1]))
        buffer = BytesIO()
        im.save(buffer, "PNG")
        img_str = base64.b64encode(buffer.getvalue())
        img.close()
        return img_str
    
    @staticmethod
    def _dataThres(v):
        if (v == 0):
            rgb = (0, 0, 0)
        elif (v < 10):
            rgb = (255, 0, 255)
        elif (v < 100):
            rgb = (0, 0, 255)
        elif (v < 1000):
            rgb = (255, 255, 0)
        else:
            rgb = (255, 0, 0)
        return rgb

    @staticmethod
    def _data2img(fname):
        with open(fname, 'rb') as f:
            data = f.read()
        d = struct.unpack("H" * ((len(data)) // 2), data)
        img = Image.new(mode="L", size=EOM.SIZE)
        diff = Image.new(mode="L", size=EOM.SIZE)
        rgb_img = Image.new(mode="RGB", size=EOM.SIZE)
        rgb = rgb_img.load()
        for j in range(EOM.SIZE[1]):
            for i in range(EOM.SIZE[0]):
                try:
                    v = d[j * EOM.SIZE[0] + i]
                    rgb[j,i] = EOM._dataThres(v)
                except Exception as inst:
                    pass
        # Laplacian mask
        diff = img.filter(ImageFilter.Kernel((3, 3), (-1, -1, -1, -1, 8,-1, -1, -1, -1), 1, 0))
        return img, rgb_img, diff
