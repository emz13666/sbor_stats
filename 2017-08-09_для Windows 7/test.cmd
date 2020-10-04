FOR /L %%i IN (1,1,30) DO (now_emz > 10.70.123.%%i.txt)&((ping 10.70.123.%%i -n 1 -w 900 >> 10.70.123.%%i.txt)&&(plink -ssh -pw unrfce20 admin@10.70.123.%%i "iwconfig ath0" >> 10.70.123.%%i.txt))
FOR /L %%i IN (60,1,81) DO (now_emz > 10.70.123.%%i.txt)&((ping 10.70.123.%%i -n 1 -w 900 >> 10.70.123.%%i.txt)&&(plink -ssh -pw unrfce20 admin@10.70.123.%%i "iwconfig ath0" >> 10.70.123.%%i.txt))
