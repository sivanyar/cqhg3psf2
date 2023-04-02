#ifndef SNDMOD_H
#define SNDMOD_H

#define BINDID_SNDMOD 0x01234567

#define SNDMOD_InitSddr   0x00
#define SNDMOD_StopSddr   0x01
#define SNDMOD_HeapInit   0x02
#define SNDMOD_QuitSddr   0x03
#define SNDMOD_TvbfAdrs   0x04
#define SNDMOD_TsqfAdrs   0x05
#define SNDMOD_TvbfTrns   0x06
#define SNDMOD_TsqfTrns   0x07
#define SNDMOD_CtrlMono   0x08
#define SNDMOD_CtrlData   0x09
#define SNDMOD_MuteData   0x0A
#define SNDMOD_AdsrData   0x0B
#define SNDMOD_HardData   0x0C
#define SNDMOD_SoftData   0x0D
#define SNDMOD_SongData   0x0E
#define SNDMOD_StopMode   0x0F
#define SNDMOD_SddrBusy   0x10
#define SNDMOD_ReadData   0x1F

#define SNDMOD_EngineInit 0x20
#define SNDMOD_EngineVols 0x21
#define SNDMOD_EngineFade 0x22
#define SNDMOD_EngineRpms 0x23
#define SNDMOD_EnginePlay 0x24
#define SNDMOD_EngineStop 0x25
#define SNDMOD_EngineMute 0x26
#define SNDMOD_EngineLoud 0x27

#define SNDMOD_RadioInit  0x30
#define SNDMOD_RadioFile  0x33
#define SNDMOD_RadioTune  0x34
#define SNDMOD_RadioPlay  0x35
#define SNDMOD_RadioStop  0x36
#define SNDMOD_RadioMute  0x37
#define SNDMOD_RadioLoud  0x38
#define SNDMOD_RadioTime  0x39

#define SNDMOD_BugsSddr   0xFFF0

#endif /* SNDMOD_H */
