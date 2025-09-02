rm -rf B09902054 B09902054.zip
mkdir B09902054
mkdir B09902054/codes

make
cp cpu_syn.v B09902054/codes
cp codes/{data_memory,instruction_memory}.v B09902054/codes
cp codes/{IF,ID,EX,cpu}.v B09902054/codes
cp {cpu.f,cpu.ys,report.pdf} B09902054

zip -r B09902054.zip B09902054
