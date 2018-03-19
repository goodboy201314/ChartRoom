// Test polynomials.
#include "pbc.h"
#include "pbc_fp.h"
#include "pbc_poly.h"
#include "pbc_test.h"
#include "darray.h"

static void elfree(void *data) {
  element_clear(data);
  pbc_free(data);
}

static void inner(void *data2, element_ptr f, field_t fx, darray_t prodlist) {
  element_ptr g = data2;
  if (!poly_degree(f) || !poly_degree(g)) return;
  if (poly_degree(f) + poly_degree(g) > 3) return;
  element_ptr h = pbc_malloc(sizeof(*h));
  element_init(h, fx);
  element_mul(h, f, g);
  darray_append(prodlist, h);
  EXPECT(!poly_is_irred(h));
}

static void outer(void *data, darray_t list, field_t fx, darray_t prodlist) {
  element_ptr f = data;
  darray_forall4(list, (void(*)(void*,void*,void*,void*))inner, f, fx, prodlist);
}

int isf(void *data, element_ptr f) {
  element_ptr f1 = data;
  return !element_cmp(f, f1);
}

