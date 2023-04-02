#include <types.h>
#include "irx_imports.h"
#include "sndmod.h"

#define RPC_SIZE_WORD 0x10U
#define RPC_SIZE_BYTE (RPC_SIZE_WORD * 4U)

const int Debug = 0;

SifRpcClientData_t SndmodClient;
u32 RpcTxBuf[RPC_SIZE_WORD];
u32 RpcRxBuf[RPC_SIZE_WORD];


void SleepForever(void)
{
  while (1) {
    SleepThread();
  }
}


void tsqdrvWakeup(void *thid)
{
  WakeupThread(*(int *)thid);
}


void tsqdrvDispData(u32 *buf, int len)
{
  int i;
  
  printf("[");
  for (i = 0; i < len; i++) {
    if (i != 0) {
      printf(" ");
    }
    printf("0x%X", (int)buf[i]);
  }
  printf("]");
}


void tsqdrvBindRpc(void)
{
  int status;
  
  if (Debug != 0) {
    printf("tsqdrv: RPC binding\n");
  }
  while (status = sceSifBindRpc(&SndmodClient, BINDID_SNDMOD, 0), status < 0) {
    if (Debug != 0) {
      printf("tsqdrv: RPC bind error %d, trying again\n", status);
    }
    DelayThread(2000);
  }
  if (Debug != 0) {
    printf("tsqdrv: RPC bind successful\n");
  }
}


void tsqdrvCallRpc(int rpc_number)
{
  int thid;
  int status;
  
  memset(RpcRxBuf, 0, RPC_SIZE_BYTE);
  if (Debug != 0) {
    printf("tsqdrv: calling RPC (0x%X) ", rpc_number);
    tsqdrvDispData(RpcTxBuf, RPC_SIZE_WORD);
    printf("\n");
  }
  thid = GetThreadId();
  status = sceSifCallRpc(&SndmodClient, rpc_number, 0, RpcTxBuf, RPC_SIZE_BYTE, RpcRxBuf, RPC_SIZE_BYTE, tsqdrvWakeup, &thid);
  if (status < 0) {
    printf("tsqdrv: RPC call error %d; giving up!\n", status);
    SleepForever();
  }
  SleepThread();
  if (Debug != 0) {
    printf("tsqdrv: RPC returned ");
    tsqdrvDispData(RpcRxBuf, RPC_SIZE_WORD);
    printf("\n");
  }
}


void tsqdrvSetReverb(int mode, short depth)
{
  int core;
  sceSdEffectAttr attr;
  
  for (core = 0; core < 2; core++)
  {
    sceSdSetAddr((u16)(core | SD_ADDR_EEA), (u32)(0x1FFFFF - ((1 - core) * 0xA0000)));
    attr.core     = core;
    attr.mode     = mode | SD_EFFECT_MODE_CLEAR;
    attr.depth_L  = depth;
    attr.depth_R  = depth;
    attr.delay    = 0x3F;
    attr.feedback = 0x3F;
    sceSdSetEffectAttr(core, &attr);
    sceSdSetCoreAttr((u16)(core | SD_CORE_EFFECT_ENABLE), 1U);
  }
}


int _start(int argc, const char *argv[])
{
  int i;
  const char *argstr;
  const char *argval;

  const u32 bank = 0U;
  const u32 tvbaddr = 0x00000000U;
  const u32 tsqaddr = 0x00000000U;
  const char *devname = "host:/";
  const size_t devnamelen = 6;

  const char *tsqfile = "BGM.TSQ";
  const char *tvbfile = "BGM.TVB";
  int songnum = 1;
  int rmode   = 3;      // SD_EFFECT_MODE_STUDIO_2
  int rdepth  = 0x3FFF; // 16383
  int mvol    = 0xB2;   // 178
  
  for (i = 1; i < argc; i++) {
    argstr = argv[i];
    argval = argstr + 3;
    if ((argstr[0] == '-') && (argstr[1] >= 'a') && (argstr[2] == '=')) {
      switch(argstr[1]) {
        case 's':
          tsqfile = argval;
          break;
        case 'b':
          tvbfile = argval;
          break;
        case 'n':
          songnum = strtol(argval, NULL, 10) & 0xFF;
          break;
        case 'r':
          rmode   = strtol(argval, NULL, 10) & 0xF;
          break;
        case 'd':
          rdepth  = strtol(argval, NULL, 10) & 0x7FFF;
          break;
        case 'v':
          mvol    = strtol(argval, NULL, 10) & 0xFF;
          break;
        default:
          break;
      }
    }
  }

  printf("tsqdrv will play %s (%d) / %s\n", tsqfile, songnum, tvbfile);
  printf("tsqdrv: binding RPC stuff\n");
  tsqdrvBindRpc();

  printf("tsqdrv: initializing E-Game IOP driver\n");
  memset(RpcTxBuf, 0, RPC_SIZE_BYTE);
  tsqdrvCallRpc(SNDMOD_InitSddr);

  memset(RpcTxBuf, 0, RPC_SIZE_BYTE);
  RpcTxBuf[0] = bank;
  RpcTxBuf[1] = tvbaddr;
  tsqdrvCallRpc(SNDMOD_TvbfAdrs);

  memset(RpcTxBuf, 0, RPC_SIZE_BYTE);
  RpcTxBuf[0] = bank;
  RpcTxBuf[1] = tsqaddr;
  tsqdrvCallRpc(SNDMOD_TsqfAdrs);

  tsqdrvSetReverb(rmode, rdepth);

  printf("tsqdrv: loading music/wave data\n");
  memset(RpcTxBuf, 0, RPC_SIZE_BYTE);
  RpcTxBuf[0] = bank;
  RpcTxBuf[1] = 0U;   // using the filepath
  strncpy((char *)&RpcTxBuf[3], devname, devnamelen);
  strncpy((char *)&RpcTxBuf[3] + devnamelen, tvbfile, RPC_SIZE_BYTE - 9U - devnamelen);
  tsqdrvCallRpc(SNDMOD_TvbfTrns);

  memset(RpcTxBuf, 0, RPC_SIZE_BYTE);
  RpcTxBuf[0] = bank;
  RpcTxBuf[1] = 0U;   // using the filepath
  strncpy((char *)&RpcTxBuf[3], devname, devnamelen);
  strncpy((char *)&RpcTxBuf[3] + devnamelen, tsqfile, RPC_SIZE_BYTE - 9U - devnamelen);
  tsqdrvCallRpc(SNDMOD_TsqfTrns);

  memset(RpcTxBuf, 0, RPC_SIZE_BYTE);
  do {
    DelayThread(10000);
    tsqdrvCallRpc(SNDMOD_SddrBusy);
  } while (RpcRxBuf[0] != 0U);

  printf("tsqdrv: play!\n");

  memset(RpcTxBuf, 0, RPC_SIZE_BYTE);
  RpcTxBuf[0] = 2U;   // set_main_vol_mode
  RpcTxBuf[1] = 0U;   // music_main_vol
  RpcTxBuf[2] = (u32)mvol;
  tsqdrvCallRpc(SNDMOD_CtrlData);

  memset(RpcTxBuf, 0, RPC_SIZE_BYTE);
  RpcTxBuf[0] = 2U;   // set_main_vol_mode
  RpcTxBuf[1] = 1U;   // sound_main_vol
  RpcTxBuf[2] = (u32)mvol;
  tsqdrvCallRpc(SNDMOD_CtrlData);

  memset(RpcTxBuf, 0, RPC_SIZE_BYTE);
  RpcTxBuf[0] = 0x40400000U | (bank << 8) | (u32)songnum;
  tsqdrvCallRpc(SNDMOD_SoftData);

  SleepForever();
  return 1;
}
