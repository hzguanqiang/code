# 去掉前几列 
cat test.txt  | awk '{ for(i=1;i<=4;i++){$i=""}; print $0 }'
