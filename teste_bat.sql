/*
@echo OFF
cls
echo . Executando scripts
osql.exe -S%1 -E -i".\010_P_MFAT_INCLUIR_PEDNF.sql" -b -h-1 -o".\010_P_MFAT_INCLUIR_PEDNF.txt" 
if errorlevel 1 goto erro
osql.exe -S%1 -E -i".\011_P_MSAR_GERAR_AUTO_NF_TRANSF_STK.sql" -b -h-1 -o".\011_P_MSAR_GERAR_AUTO_NF_TRANSF_STK.txt"
if errorlevel 1 goto erro
goto sucesso
:erro
echo -------------------------------------------------
echo Ocorreram 1 ou mais erros ao executar os scripts, verifique o arquivo de log no mesmo diretorio
pause
goto end
:sucesso
echo -------------------------------------------------
echo Os scripts foram executados com sucesso
pause
:end
*/
osql.exe -S%1 -E -i".\010_P_MFAT_INCLUIR_PEDNF.sql" -b -h-1 -o".\010_P_MFAT_INCLUIR_PEDNF.txt" 

osql.exe -S%1 -E -i".\testeosql.sql" -b -h-1 -o".\testeosql.txt" 

-S - server
-E - trusted connection
-i - inputFile
-b - cod retorno erro
-h - header, nr de linha a imprimir, -1 não imprime nada
-o - outputFile

sqlcmd.exe -S%1 -E -i".\testesqlcmd.sql" -b -h-1 -o".\testesqlcmd.txt" 
sqlcmd.exe -SSQLDEVDEP -E -i".\testesqlcmd.sql" -b -h-1 -o".\testesqlcmd.txt" 

sqlcmd.exe -SSQLDEVDEP -E -i"C:\Reinaldo\FNAC\Scripts\Testes\testesqlcmd.sql" -b -h-1 -o"C:\Reinaldo\FNAC\Scripts\Testes\testesqlcmd.txt" 
osql.exe -SSQLDEVDEP -E -i"C:\Reinaldo\FNAC\Scripts\Testes\testeosql.sql" -b -h-1 -o"C:\Reinaldo\FNAC\Scripts\Testes\testeosql.txt"

