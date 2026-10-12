___HIDDEN void mark_frame
   ___P((___PSD
         ___WORD *fp,
         int fs,
         ___WORD gcmap,
         ___WORD *nextgcmap),
        (___PSV
         fp,
         fs,
         gcmap,
         nextgcmap)
___PSDKR
___WORD *fp;
int fs;
___WORD gcmap;
___WORD *nextgcmap;)
{
  int i = 1;

  for (;;)
    {
      if (gcmap & 1)
        {
          int j = i;
          do
            {
              if (i == fs)
                {
#ifdef SHOW_FRAMES
                  {
                    int k = j;
                    while (k <= i)
                      {
                        ___WORD obj = ___FP_STK(fp,k);
                        ___printf ("  %2d: ", k);
                        print_value (obj);
                        ___printf ("\n");
                        k++;
                      }
                  }
#endif
                  mark_array (___PSP &___FP_STK(fp,i), i-j+1);
                  return;
                }
              if ((i & (___WORD_WIDTH-1)) == 0)
                gcmap = *nextgcmap++;
              else
                gcmap >>= 1;
              i++;
            } while (gcmap & 1);
#ifdef SHOW_FRAMES
          {
            int k = j;
            while (k < i)
              {
                ___WORD obj = ___FP_STK(fp,k);
                ___printf ("  %2d: ", k);
                print_value (obj);
                ___printf ("\n");
                k++;
              }
          }
#endif
          mark_array (___PSP &___FP_STK(fp,i-1), i-j);
        }
      if (i == fs)
        return;
      if ((i & (___WORD_WIDTH-1)) == 0)
        {
          gcmap = *nextgcmap++;
#ifdef SHOW_FRAMES
          ___printf ("gcmap = 0x%" ___PRIxWORD "\n", gcmap);
#endif
        }
      else
        gcmap >>= 1;
      i++;
    }
}


