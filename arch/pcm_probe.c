#include <freerdp/codec/dsp.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
int main(void) {
 AUDIO_FORMAT f={WAVE_FORMAT_PCM,2,44100,176400,4,16,0,NULL};
 int16_t samples[2048];
 for (int i=0;i<2048;i++) samples[i]=(i%3==0)?-12000:(i%3==1?0:12000);
 FREERDP_DSP_CONTEXT *ctx=freerdp_dsp_context_new(TRUE);
 wStream *out=Stream_New(NULL,16384);
 if (!ctx||!out||!freerdp_dsp_context_reset(ctx,&f,1024)||!freerdp_dsp_encode(ctx,&f,(const BYTE*)samples,sizeof(samples),out)) return 2;
 size_t n=Stream_GetPosition(out);
 int equal=n==sizeof(samples)&&memcmp(Stream_Buffer(out),samples,n)==0;
 printf("PCM16 frames=1024 bytes=%zu exact_signed_samples=%s\n",n,equal?"true":"false");
 freerdp_dsp_context_free(ctx); Stream_Free(out,TRUE);
 return equal?0:1;
}
