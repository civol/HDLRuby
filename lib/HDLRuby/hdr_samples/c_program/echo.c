#include <stdio.h>
#include "cHDL.h"

#if defined(_WIN32) || defined(_WIN64)
__declspec(dllexport)
#endif
void echo(void* code) {
    static void* inP = NULL;
    static void* outP = NULL;
    unsigned long long data;

    /* Is the input port obtained? */
    if (inP == NULL) {
        /* No, get it. */
        inP = c_get_port("inP");
    }

    /* Is the input port obtained? */
    if (outP == NULL) {
        /* No, get it. */
        outP = c_get_port("outP");
    }

    /* Get data from the input port. */
    data = c_read_port(inP);

    /* Display it. */
    printf("Echoing: %llu\n", data);

    /* Echoing the data. */
    c_write_port(outP,data);

}
