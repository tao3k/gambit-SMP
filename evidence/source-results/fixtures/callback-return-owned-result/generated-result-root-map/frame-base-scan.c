        ___FP_ADJFP(fp,-___FRAME_SPACE(fs)) /* get base of frame */

        ra2 = ___FP_STK(fp,link+1);

#ifdef SHOW_FRAMES
        if (fp == ___ps->stack_break)
          ___printf ("  (first frame above break frame)\n");
#endif

        mark_frame (___PSP fp, fs, gcmap, nextgcmap);