#主程序
import xlrd
import cv2
import os

#获取图片编号去找到对应图片测试代码
#读取xls文件的数据
xls_data=xlrd.open_workbook("2.xls")
table=xls_data.sheet_by_index(0)
dcmnumber=table.col_values(2)
minx=table.col_values(3)
miny=table.col_values(4)
maxx=table.col_values(5)
maxy=table.col_values(6)
minx=[int(x) for x in minx]
miny=[int(x) for x in miny]
maxx=[int(x) for x in maxx]
maxy=[int(x) for x in maxy]
dcmnumber=[int(x) for x in dcmnumber]
dcmnumber=[str(x) for x in dcmnumber]

#去画框图

img_dir='E:\Study\Research\Program\Summer\Fenge\dicom'
path='E:\Study\Research\Program\LIDC-IDRL'
os.mkdir(path + './imgnew')

for num in range(len(dcmnumber)):
    path2=os.path.join(img_dir,dcmnumber[num]+'.jpg')
    img1=cv2.imread(path2)
    img2=cv2.rectangle(img1,(minx[num],maxy[num]),(maxx[num],miny[num]),(255,0,0),2)
    path3=os.path.join(path,'imgnew',dcmnumber[num]+'.jpg')
    mg3=cv2.imwrite(path3,img2)




