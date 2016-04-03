#include <caml/alloc.h>
#include <caml/threads.h>
#include <caml/fail.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/signals.h>
#include <caml/custom.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <c_urg/urg_ctrl.h>

static value Val_some(value v)
{
  CAMLparam1(v);
  CAMLlocal1(res);
  res = caml_alloc(1,0);
  Field(res,0) = v;
  CAMLreturn(res);
}
static value Val_none = Val_unit;

static urg_t* Urg_val(value v) {
  return((urg_t*) v);
}

static value Val_urg(urg_t* urg) {
  return((value) urg);
}

CAMLprim value ocaml_urg_disconnect(value vurg) {
  urg_t *urg = Urg_val(vurg);
  urg_disconnect(urg);
  free(urg);
  return(Val_unit);
}

CAMLprim value ocaml_urg_connect(value vdevice, value vspeed) {
  CAMLparam2(vdevice, vspeed);
  CAMLlocal1(vret);
  urg_t *urg = malloc(sizeof(urg_t));
  char *device = String_val(vdevice);
  int ret;
  ret = urg_connect(urg, device, Long_val(vspeed));
  if(ret < 0) {
    free(urg);
    CAMLreturn(Val_none);
  }
  CAMLreturn(Val_some(Val_urg(urg)));
}

CAMLprim value ocaml_urg_dataMax(value vurg) {
  return(Val_long(urg_dataMax(Urg_val(vurg))));
}

CAMLprim value ocaml_urg_requestData(value vurg, value vtype) {
  return(Val_long(urg_requestData(Urg_val(vurg), Long_val(vtype), URG_FIRST, URG_LAST)));
}

CAMLprim value ocaml_urg_receiveData(value vurg, value vbuf) {
  CAMLparam2(vurg,vbuf);
  long* data = Data_bigarray_val(vbuf);
  int rows = Bigarray_val(vbuf)->dim[0];
  int ret;
  caml_release_runtime_system();
  ret = urg_receiveData(Urg_val(vurg), data, rows);
  caml_acquire_runtime_system();
  CAMLreturn(Val_long(ret));
}

CAMLprim value ocaml_urg_recentTimestamp(value vurg) {
  return(Val_long(urg_recentTimestamp(Urg_val(vurg))));
}

CAMLprim value ocaml_urg_scanMsec(value vurg) {
  return(Val_long(urg_scanMsec(Urg_val(vurg))));
}

CAMLprim value ocaml_urg_maxDistance(value vurg) {
  return(Val_long(urg_maxDistance(Urg_val(vurg))));
}

CAMLprim value ocaml_urg_minDistance(value vurg) {
  return(Val_long(urg_minDistance(Urg_val(vurg))));
}

CAMLprim value ocaml_urg_setCaptureTimes(value vurg, value vtimes) {
  return(Val_long(urg_setCaptureTimes(Urg_val(vurg),Long_val(vtimes))));
}

CAMLprim value ocaml_urg_remainCaptureTimes(value vurg) {
  return(Val_long(urg_remainCaptureTimes(Urg_val(vurg))));
}

CAMLprim value ocaml_urg_index2rad(value vurg, value vindex) {
  CAMLparam2(vurg, vindex);
  CAMLreturn(caml_copy_double(urg_index2rad(Urg_val(vurg), Long_val(vindex))));
}

extern int urg_reboot(urg_t *urg);

CAMLprim value ocaml_urg_reboot(value vurg) {
  return(Val_long(urg_reboot(Urg_val(vurg))));
}

#define MAX_VERSION_LINES 10

CAMLprim value ocaml_urg_versionLines(value vurg) {
  CAMLparam1(vurg);
  CAMLlocal2(vret, vstring);
  char lines[MAX_VERSION_LINES][UrgLineWidth];
  char *linesp[MAX_VERSION_LINES];
  int i;
  for(i = 0; i < MAX_VERSION_LINES; i++) {
    linesp[i] = (char*) &lines[i];
  }
  urg_t *urg = Urg_val(vurg);
  if(urg_versionLines(urg,linesp,MAX_VERSION_LINES)) {
    CAMLreturn(Val_none);
  }
  vret = caml_alloc_tuple(MAX_VERSION_LINES);
  for(i = 0; i < MAX_VERSION_LINES; i++) {
    Field(vret, i) = caml_copy_string(linesp[i]);
  }
  CAMLreturn(Val_some(vret));
}
