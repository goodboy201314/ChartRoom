// For different discriminants D, list group size and representation size
// of resulting MNT curves.

#include "pbc.h"

int consider(pbc_cm_t cm, void *data) {
  unsigned int D = * (unsigned *) data;
  int qbits, rbits;
  qbits = mpz_sizeinbase(cm->q, 2);
  rbits = mpz_sizeinbase(cm->r, 2);
  printf("%d, %d, %d\n", D, qbits, rbits);
  fflush(stdout);
  return 0;
}
/**
void try(unsigned int D) {
  pbc_cm_search_d(consider, &D, D, 500);
}
 **/
