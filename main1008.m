clear;clc;
folder_name_all = uigetdir('');%选择文件夹
img_path_list = dir(strcat(folder_name_all,'\','*.dcm'));% 获取该文件夹中所有格式的图像  
xml_path_list = dir(strcat(folder_name_all,'\','*.xml'));


%%  读取xml文件部分，只提取3mm-33mm的结节
xml_name = xml_path_list.name;
docNode= xmlread(strcat(folder_name_all,'\',xml_name));
document = docNode.getDocumentElement();
readingSession = document.getElementsByTagName('readingSession');


num_mal = []; %每个结节的恶性度和属于该类别的图片的数量
sop_text = { }; %每个图片的标号
max_min_xy = []; %每个图像中肺结节的x和y的最小值和最大值
sop_num = 0;         %总结节个数？*


for r = 0:readingSession.getLength()-1
    unblinded_nodule = readingSession.item(r).getElementsByTagName('unblindedReadNodule');     %unblindedReadNodule一个节点标记，<unblindedReadNodule>节点数据包括在</unblindedReadNodule>*
    
    for u = 0 : unblinded_nodule.getLength()-1
        
        roi = unblinded_nodule.item(u).getElementsByTagName('roi');   %item() 方法可返回节点列表中处于指定索引号的节点。*<roi>结节轮廓</roi>*
        mal = unblinded_nodule.item(u).getElementsByTagName('malignancy');    %<malignancy>结节恶性度</malignancy>*
        %如果xml文件中没有malignancy或者roi标签直接跳过
        if isempty(roi.item(0))
            continue;
        end
        if isempty(mal.item(0))
            continue;
        end
        
        Num_roi = roi.getLength();   %该类别的图片的数量
        mal_int = str2num(char(mal.item(0).getTextContent()));%0是因为只有这一项，所以是item（0）
        num_mal = [num_mal();mal_int,Num_roi];%这个结构在构建数组，不会覆盖上次的值
        
        for i = 0 : Num_roi-1  %遍历*
            sop_id = roi.item(i).getElementsByTagName('imageSOP_UID');    %图片编号*
            sop_text{sop_num + i + 1} = char(sop_id.item(0).getTextContent());   %数组*
            edgeMap = roi.item(i).getElementsByTagName('edgeMap');   %边界*
            xy = [];
            for j = 0 :edgeMap.getLength()-1            %获得坐标*
                xCoord = edgeMap.item(j).getElementsByTagName('xCoord');
                xCoord_int = str2num(char(xCoord.item(0).getTextContent()));
                
                yCoord = edgeMap.item(j).getElementsByTagName('yCoord');
                yCoord_int = str2num(char(yCoord.item(0).getTextContent()));
                xy=[xy();xCoord_int,yCoord_int];
            end
            
            if edgeMap.getLength()==1
                max_min_xy = [max_min_xy();xy,xy];%如果是小结节，直接使用这个坐标即可
                continue;
            end
            [maxr,max_index] = max(xy);%因为坐标比较多，所以筛选出边缘坐标
            [minr,min_index] = min(xy);%为了后续的操作我应该要得到左上角和右下角的坐标
            max_min_xy = [max_min_xy();minr,maxr];
            
            
        end
        
        sop_num= Num_roi+sop_num;   %总个数
        
    end
    if isempty(num_mal)
        continue;
    end
%     num_mal = [num_mal();0,0];    %扩展维数*
end

%% 进行扩展维度以方便最后导入xls文件中
sop_num = size(sop_text);   %  获得行列数，行：？ 列：图片数*
mal_num = size(num_mal);        %行： 图片数？*
dcm_number = [ ];   %图片编号*    
        
if sop_num(2)>mal_num(1)           %要根据他们两个的差值来决定补多少个0
    for m = 1 : sop_num(2)-mal_num(1)
        num_mal = [num_mal();0,0];    %添加扩展维度*
    end
end
if sop_num(2)< mal_num(1)
    for m = 1 :  mal_num(1) - sop_num(2)     %  只有数据维度一样才能被写入到文件中！所以少的要补上四个0
        dcm_number= [dcm_number;0];            %添加扩展维度
        max_min_xy = [max_min_xy;0,0,0,0];       %添加扩展维度
    end
end

        
%%  读取dicom文件头信息
for md= 1 : sop_num(2)      %修正维数           
    dcm_number= [dcm_number;0];
end
for j = 1:numel(img_path_list)    %遍历文件 numel()函数返回数组个数
    image_name = img_path_list(j).name;  %  图像名
    dicomInformation = dicominfo(strcat(folder_name_all,'\',image_name)); %存储图片信息
    instance = dicomInformation.SOPInstanceUID;   
    imagenum = dicomInformation.InstanceNumber; 
%                     ins_number(j)=instance;
    dcm_number(j) = imagenum;
for s = 1 : sop_num(2)    %对比
    if strcmpi(instance,sop_text(1,s))
        dcm_number(s) = imagenum;     %编号？？?*
    end
end
total = [num_mal,dcm_number,max_min_xy];
if isempty(total)
    continue;
end
% child_path =
xlswrite('1.xls',total);     %导入到表格中 2017/4/10


end

