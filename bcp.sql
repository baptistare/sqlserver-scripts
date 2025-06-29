bcp "select * from sgf_cadr.dbo.MCAD_PRODUTO where dt_cadastro >= '20151215' and cd_Area = 4 and cd_categoria = 7 and cd_produto in ('0000071196824', '0000071197128','0000071197203','0000071197395')" queryout "C:\temp\BCP\MCAD_PRODUTO.dat" -S MSCOMERCIAL -T -N

bcp SGF_CADR..MCAD_PRODUTO in c:\temp\BCP\MCAD_PRODUTO.dat -S SQLDESENV2\MSCOMERCIAL -T -N
