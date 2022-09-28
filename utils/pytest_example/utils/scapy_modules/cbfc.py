from scapy.packet import Packet
from scapy.fields import XBitField
from scapy.layers.l2 import ShortEnumField, ShortField, bind_layers, Ether, Packet
from scapy.packet import Padding


def padd(self, pad_len=60):
    pad_len = pad_len - len(self)
    if pad_len < 0:
        return self
    pad = Padding()
    pad.load = '\x00' * pad_len
    self = self / pad
    return self

Packet.Padd = padd

class CBFC(Packet):
	name= "Class Based Flow Control"
	Opcode=0x0101
	Nb_Class=8
	fields_desc = [ XBitField("Class_Enable_Vector", 0xff, 16) ] + [ ShortField("C%d"%i,0) for i in range(Nb_Class) ]

class Pause(Packet):
	name= "Pause"
	Opcode=0x0001
	fields_desc = [ ShortField("pause_time", 0)]
	

class MacControl(Packet):
	name = "MAC Control"
	Type=0x8808
	fields_desc = [ ShortEnumField("Opcode", Pause.Opcode , {CBFC.Opcode: CBFC.name, Pause.Opcode: Pause.name})]

bind_layers( Ether, MacControl, type=MacControl.Type)
bind_layers( MacControl, Pause, Opcode=Pause.Opcode)
bind_layers( MacControl, CBFC, Opcode=CBFC.Opcode)


