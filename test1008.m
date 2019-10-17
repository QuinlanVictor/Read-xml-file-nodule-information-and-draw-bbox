clear;clc;
folder_name_all = uigetdir('');%ѡ���ļ���
img_path_list = dir(strcat(folder_name_all,'\','*.dcm'));% ��ȡ���ļ��������и�ʽ��ͼ��  
xml_path_list = dir(strcat(folder_name_all,'\','*.xml'));


%%  ��ȡxml�ļ����֣�ֻ��ȡ3mm-33mm�Ľ��
xml_name = xml_path_list.name;
docNode= xmlread(strcat(folder_name_all,'\',xml_name));
document = docNode.getDocumentElement();
readingSession = document.getElementsByTagName('readingSession');


num_mal = []; %ÿ����ڵĶ��ԶȺ����ڸ�����ͼƬ������
sop_text = { }; %ÿ��ͼƬ�ı��
max_min_xy = []; %ÿ��ͼ���зν�ڵ�x��y����Сֵ�����ֵ
sop_num = 0;         %�ܽ�ڸ�����*


for r = 0:readingSession.getLength()-1
    unblinded_nodule = readingSession.item(r).getElementsByTagName('unblindedReadNodule');     %unblindedReadNoduleһ���ڵ��ǣ�<unblindedReadNodule>�ڵ����ݰ�����</unblindedReadNodule>*
    
    for u = 0 : unblinded_nodule.getLength()-1
        
        roi = unblinded_nodule.item(u).getElementsByTagName('roi');   %item() �����ɷ��ؽڵ��б��д���ָ�������ŵĽڵ㡣*<roi>�������</roi>*
        mal = unblinded_nodule.item(u).getElementsByTagName('malignancy');    %<malignancy>��ڶ��Զ�</malignancy>*
        %���xml�ļ���û��malignancy����roi��ǩֱ������
        if isempty(roi.item(0))
            continue;
        end
        if isempty(mal.item(0))
            continue;
        end
        
        Num_roi = roi.getLength();   %������ͼƬ������
        mal_int = str2num(char(mal.item(0).getTextContent()));%0����Ϊֻ����һ�������item��0��
        num_mal = [num_mal();mal_int,Num_roi];%����ṹ�ڹ������飬���Ḳ���ϴε�ֵ
        
        for i = 0 : Num_roi-1  %����*
            sop_id = roi.item(i).getElementsByTagName('imageSOP_UID');    %ͼƬ���*
            sop_text{sop_num + i + 1} = char(sop_id.item(0).getTextContent());   %����*
            edgeMap = roi.item(i).getElementsByTagName('edgeMap');   %�߽�*
            xy = [];
            for j = 0 :edgeMap.getLength()-1            %�������*
                xCoord = edgeMap.item(j).getElementsByTagName('xCoord');
                xCoord_int = str2num(char(xCoord.item(0).getTextContent()));
                
                yCoord = edgeMap.item(j).getElementsByTagName('yCoord');
                yCoord_int = str2num(char(yCoord.item(0).getTextContent()));
                xy=[xy();xCoord_int,yCoord_int];
            end
            
            if edgeMap.getLength()==1
                max_min_xy = [max_min_xy();xy,xy];%�����С��ڣ�ֱ��ʹ��������꼴��
                continue;
            end
            [maxr,max_index] = max(xy);%��Ϊ����Ƚ϶࣬����ɸѡ����Ե����
            [minr,min_index] = min(xy);%Ϊ�˺����Ĳ�����Ӧ��Ҫ�õ����ϽǺ����½ǵ�����
            max_min_xy = [max_min_xy();minr,maxr];
            
            
        end
        
        sop_num= Num_roi+sop_num;   %�ܸ���
        
    end
    if isempty(num_mal)
        continue;
    end
%     num_mal = [num_mal();0,0];    %��չά��*
end

%% ������չά���Է��������xls�ļ���
sop_num = size(sop_text);   %  ������������У��� �У�ͼƬ��*
mal_num = size(num_mal);        %�У� ͼƬ����*
dcm_number = [ ];   %ͼƬ���*    
        
if sop_num(2)>mal_num(1)           %Ҫ�������������Ĳ�ֵ�����������ٸ�0
    for m = 1 : sop_num(2)-mal_num(1)
        num_mal = [num_mal();0,0];    %�����չά��*
    end
end
if sop_num(2)< mal_num(1)
    for m = 1 :  mal_num(1) - sop_num(2)     %  ֻ������ά��һ�����ܱ�д�뵽�ļ��У������ٵ�Ҫ�����ĸ�0
        dcm_number= [dcm_number;0];            %�����չά��
        max_min_xy = [max_min_xy;0,0,0,0];       %�����չά��
    end
end

        
%%  ��ȡdicom�ļ�ͷ��Ϣ
for md= 1 : sop_num(2)      %����ά��           
    dcm_number= [dcm_number;0];
end
for j = 1:numel(img_path_list)    %�����ļ� numel()���������������
    image_name = img_path_list(j).name;  %  ͼ����
    dicomInformation = dicominfo(strcat(folder_name_all,'\',image_name)); %�洢ͼƬ��Ϣ
    instance = dicomInformation.SOPInstanceUID;   
    imagenum = dicomInformation.InstanceNumber; 
%                     ins_number(j)=instance;
    dcm_number(j) = imagenum;
for s = 1 : sop_num(2)    %�Ա�
    if strcmpi(instance,sop_text(1,s))
        dcm_number(s) = imagenum;     %��ţ���?*
    end
end
total = [num_mal,dcm_number,max_min_xy];
if isempty(total)
    continue;
end
% child_path =
xlswrite('1.xls',total);     %���뵽����� 2017/4/10


end

