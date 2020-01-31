clear all; close all; clc;

files = dir('eu/*.txt');

counter = 0;
for i=1:length(files)
    fileID = fopen([files(i).folder '/' files(i).name],'r');
    text = textscan(fileID, '%s');text = text{1};
    fclose(fileID);

    imgOrg = imread([files(i).folder '/' text{1}],'jpg');

    img = getImageTransform(imgOrg);
    best = getPlate(img);

    if(size(best) == 0)
        continue;
    end

    centroid = best.Centroid;

    posX = str2num(text{2});posY = str2num(text{3});
    width = str2num(text{4});height = str2num(text{5});
    textCentorid = [(width/2)+posX (height/2)+posY];

    marginV = 0.1;
    margin = [width*marginV height*marginV];
    difference = centroid - textCentorid;
    result = margin > difference;
    if (result == true)
        counter = counter + 1;
    end
end
disp(counter/length(files));




function imgRes = getImageTransform(imgOrg)
    img = rgb2gray(imgOrg);
    
    img = imresize(img, [400 600]);
    img = imadjust(img);   
    
    % ustawienia
    % 0.7315
    seRecon1 = ones(31,1);
    seRecon2 = ones(17,2);
    seClose = ones(1,12);
    cannyValue = 0.63;

%     figure(1);
%     subplot(1,2,1);imshow(imgOrg, 'InitialMagnification','fit');title('RGB');
%     subplot(1,2,2);imshow(img, 'InitialMagnification','fit');title('Gray');
    
    imgRecon = imreconstruct(imerode(img, seRecon1), img);
%     figure(2);
%     subplot(1,4,1);imshow(imgRecon, 'InitialMagnification','fit');title(['Rekonstrukcja morfologiczna po ' newline 'erozji z orgina³em w skali szaroœci']);
    imgSub = imsubtract(img, imgRecon);
%     subplot(1,4,2);imshow(imgSub, 'InitialMagnification','fit');title(['Ró¿nica obraz po rekonstrukcji' newline 'z tym w skali szaroœci']);
    imgRecon2 = imreconstruct(imerode(imgSub, seRecon2), imgSub);
%     subplot(1,4,3);imshow(imgRecon2, 'InitialMagnification','fit');title(['Druga rekonstrukcja morfologiczna po ' newline 'erozji z ró¿nic¹']);
    imgDilate = imdilate(imgRecon2, seRecon2);
%     subplot(1,4,4);imshow(imgDilate, 'InitialMagnification','fit');title(['Dylatacja obrazu po drugiej rekonstrukcji' newline 'z elementem strukturalnym']);
    
%     figure(3);
    img = imreconstruct(min(imgSub, imgDilate), imgSub);
%     subplot(1,2,1);imshow(img, 'InitialMagnification','fit');title(['Kolejna rekonstrukcja na podstawie poprzednich operacji']);
    img = edge(img,'canny',cannyValue);
%     subplot(1,2,2);imshow(img, 'InitialMagnification','fit');title('Wykrycie krawêdzi metod¹ Canniego');
    
%     figure(4);
    img = imclose(img, seClose);
%     subplot(1,3,1);imshow(img, 'InitialMagnification','fit');title('Morfologiczne domkniêcie');
    img = imfill (img, "holes");
%     subplot(1,3,2);imshow(img, 'InitialMagnification','fit');title('Wype³nienie zamkniêtych obszarów');
    img = bwareaopen(img, 400);
%     subplot(1,3,3);imshow(img, 'InitialMagnification','fit');title(['Usuniêcie obszarów które maj¹ mniej ni¿ 400' newline 'wype³nionych pixeli']);
    
    sizeOrg = size(imgOrg);
    img = imresize(img, [sizeOrg(1) sizeOrg(2)]);
    imgRes = img;
end

function best = getPlate(img)
    stats = regionprops(img,'FilledArea','Area','BoundingBox', 'Centroid');
    best = [];
    bestScore = 0;
    for j = 1:size(stats)
        stat = stats(j);
        m = stat.BoundingBox;
        score = stat.FilledArea/(m(3)*m(4)); % wynik wype³nienia obszaru
%         disp([num2str(i) ' = ' num2str((m(3)/m(4))) ' ' num2str(score)]);
        
        if( (m(3)/m(4))>2.3 && score>bestScore ) % sprawdzenie czy wys jest mniejsza conajmniej x2,5 raza
            best = stat;
        end
    end
%     bestM = best.BoundingBox;
%     disp([num2str(i) ' = ' num2str(best.Centroid)]);
%     imshow(imcrop(imgOrg, [bestM(1),bestM(2),bestM(3),bestM(4)]), 'InitialMagnification','fit');
end