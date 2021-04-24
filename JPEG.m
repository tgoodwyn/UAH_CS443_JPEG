% CS443-01 
% Project: JPEG Implementation
% Team 1 - Jordan Biffle, Keyara Coleman, Tyler Goodwyn
% Leonie Nutz, Nicholas Zwolinski




function o=JPEG(image)
    close all;
    % clear all;
    clc;



    %% Read Image
    %I = imread('tulips.png');
    I = imread(image); % will be padded if necessary
    ogIMG = I; % will be used for error calculation
    figure(1);
    subplot(3,3,1),imshow(I),title("Original image");
    
    
    blockBeforeS1=I(1:8,1:8,:);
    blockBeforeS1
    figure(1);
    subplot(3,3,2),imshow(blockBeforeS1),title("First 8x8 block before Step 1");
    f=split(image,".");
    imwrite(blockBeforeS1,append("input_",f(1),"_8x8_S1.png"));

    %% pad the image to make pixels in multiples of 16
    [m,n,~]=size(I);
    pad_x = rem(m,16);
    pad_y = rem(n,16);
    if pad_x ~= 0
        pad_x = 16 - pad_x;
    end
    if pad_y ~= 0
        pad_y = 16 - pad_y;
    end
    I = padarray(I,[pad_x/2 pad_y/2 0],'replicate','both');

    %% convert image to YCbCr format
    I2 = rgb2ycbcr(I);
    %figure(2);
    %imshow(I2);

    %% Perform chroma subsampling 4:2:0 on color components Cb and Cr individually
    % Downsample from [m,n] to [m/2, n/2]
    nY = I2(:,:,1);
    nCb=downSample420(I2(:,:,2));
    nCr=downSample420(I2(:,:,3));

    %% Performing dct in blocks of 8x8
    % 8 is the size of the 8x8 block being DCTed.
    C = create_c_matrix(8);

    nnY = perform_dct(nY,C);
    nnCb = perform_dct(nCb,C);
    nnCr = perform_dct(nCr,C);
    

    %% Quantization matrices

    Y_Table=[16 11  10  16 24  40  51 61
            12  12  14 19  26  58 60  55
            14  13  16 24  40  57 69  56
            14  17  22 29  51  87 80  62
            18  22  37 56  68 109 103 77
            24  35  55 64  81 104 113 92
            49  64  78  87 103 121 120 101
            72  92  95  98 112 100 103  99];%Luminance quantization table

    CbCr_Table=[17, 18, 24, 47, 99, 99, 99, 99;
                18, 21, 26, 66, 99, 99, 99, 99;
                24, 26, 56, 99, 99, 99, 99, 99;
                47, 66, 99 ,99, 99, 99, 99, 99;
                99, 99, 99, 99, 99, 99, 99, 99;
                99, 99, 99, 99, 99, 99, 99, 99;
                99, 99, 99, 99, 99, 99, 99, 99;
                99, 99, 99, 99, 99, 99, 99, 99];%Color difference quantization table

    %% Performing quantization
    nnnY = perform_quantization(nnY,Y_Table);
    nnnCb = perform_quantization(nnCb,CbCr_Table);
    nnnCr = perform_quantization(nnCr,CbCr_Table);
    
    %% Output and show first 8x8 block after Step 1, only works if image is in same folder as code
    
    blockAfterS1=cat(3,nnnY(1:8,1:8),nnnCb(1:8,1:8),nnnCr(1:8,1:8));
    blockAfterS1
    fn=append("output_",f(1),"_8x8_S1.png");
    imwrite(blockAfterS1,fn);
    
    figure(1)
    subplot(3,3,3),imshow(blockAfterS1),title("First 8x8 block after S1");

    %% Output and show image output by Step 1
    
    imageAfterS1=cat(3,nnnY,upSample420(nnnCb,[m+pad_x n+pad_y]),upSample420(nnnCr,[m+pad_x n+pad_y]));
    fn=append(f(1),"_ImageAfterS1.png");
    imwrite(imageAfterS1,fn);
    
    figure(1)
    subplot(3,3,4),imshow(imageAfterS1),title("Image after Step 1");

    
    %% Now performing all steps in reverse
    % Performing Inverse quantization

    new_nnnY = perform_inverse_quantization(nnnY,Y_Table);
    new_nnnCb = perform_inverse_quantization(nnnCb,CbCr_Table);
    new_nnnCr = perform_inverse_quantization(nnnCr,CbCr_Table);

    %% Performing Inverse DCT

    new_nnY = perform_inverse_dct(new_nnnY,C);
    new_nnCb = perform_inverse_dct(new_nnnCb,C);
    new_nnCr = perform_inverse_dct(new_nnnCr,C);
    
    
    %% Upsample from [m/2,n/2] to [m, n]

    
    new_nY = new_nnY;
    new_nCb = upSample420(new_nnCb,[m+pad_x n+pad_y]);
    new_nCr = upSample420(new_nnCr,[m+pad_x n+pad_y]);
    %new_nCb=imresize(new_nnCb,2,'bilinear');
    %new_nCr=imresize(new_nnCr,2,'bilinear');

    %% Concatenating, and reconverting to RGB

    
    final_im = cat(3,new_nY,new_nCb,new_nCr);
    final_im = ycbcr2rgb(final_im); 
    

    
    %% Removing padding

    final_im = final_im((pad_x/2)+1:(pad_x/2)+m , (pad_y/2)+1:(pad_y/2)+n , :);

    %% Show and output first 8x8 block after step 2 and final image
    blockAfterS2=final_im(1:8,1:8,:);
    blockAfterS2
    
    imwrite(blockAfterS2,append("output_",f(1),"_8x8_S2.png"));
    
    figure(1);
    subplot(3,3,5),imshow(blockAfterS2),title("First 8x8 block after S2");
    
    
    figure(1);
    subplot(3,3,6),imshow(final_im),title("Image after Step 2/Final image");
    
    %imwrite(final_im,'tulips_new.png');
    imwrite(final_im,append("output_",image,".png"));
    
    o=final_im;
    %% Error calculations
    % this function returns the PSNR, displays the error map
    psnr = calculate_errors(ogIMG, final_im);
    disp("PSNR = "+psnr)
    function C = create_c_matrix(N)
        % N is the size of the NxN block being DCTed.
        % Create C
        C = zeros(N,N);
        for mm = 0:1:N-1
            for nn = 0:1:N-1
                if nn == 0
                k = sqrt(1/N);
                else
                k = sqrt(2/N);
                end
            C(mm+1,nn+1) = k*cos( ((2*mm+1)*nn*pi) / (2*N));
            end
        end
    end
    function [new_Im]=downSample420(I)
        % Size of Input Image
        % m = no of Rows
        % n= no of Columns
        I = double(I);
        [mm,nn]=size(I);   
        r=1;
        %Downsample Image from [m,n] to [m/2,n/2] using Chroma 420 
        for i=1:2:mm-1
            c=1;
            for j=1:2:nn-1
                new_Im(r,c)=(I(i,j)+I(i,j+1)+I(i+1,j)+I(i+1,j+1))/4;
                c=c+1;
            end
            r=r+1;
        end
        if((2*(r-1))~=mm)
            new_Im(r,:)=new_Im(r-1,:);
        end
        if((2*(c-1))~=nn)
            new_Im(:,c)=new_Im(:,c+1);
        end
        new_Im = uint8(new_Im);
    end
    function [new_Im]=perform_dct(I,C)

        % function for performing dct
        dct = @(block_struct) C * block_struct.data * C';

        I=double(I) - 128;  %Level shift128Gray levels

        % performing dct in blocks of 8x8,
        new_Im = blockproc(I,[8 8],dct);

    end
    function [new_Im]=perform_inverse_dct(I,C)

        % function for performing inverse dct
        invdct = @(block_struct) C' * block_struct.data * C;

        % performing inverse dct in blocks of 8x8,
        % then rounding result, then converting to uint8
        new_Im = round(blockproc(I,[8 8],invdct));

        % reversing gray level shift
        new_Im = uint8(new_Im + 128);

        % limiting out of range pixel values
        [row,column]=size(new_Im);
        for i=1:row
            for j=1:column
                if new_Im(i,j)>255
                    new_Im(i,j)=255;
                elseif new_Im(i,j)<0
                    new_Im(i,j)=0;
                end
            end
        end

    end
    function [new_Im]=perform_inverse_quantization(I,quan_mat)

        % function for performing quantization
        qua_func = @(block_struct) block_struct.data .* quan_mat;

        new_Im = blockproc(I,[8 8],qua_func);

    end
    function [new_Im]=perform_quantization(I,quan_mat)

        % function for performing quantization
        qua_func = @(block_struct) round(block_struct.data ./ quan_mat);

        new_Im = blockproc(I,[8 8],qua_func);

    end
    function [new_Im]=upSample420(I,V)
        % Size of Input Image
        % m = no of Rows
        % n= no of Columns
        [mm,nn]=size(I);   
        r=1;
        %Upsample Image from [m/2,n/2] to [m,n] 
        for i=1:V(1)
            c=1;
            for j=1:V(2)
                new_Im(i,j)=I(round(i/2),round(j/2));
                c=c+1;
            end
            r=r+1;
        end
    end

    function [psnr] = calculate_errors(ogIMG, finalIMG)
        ogIMG = rgb2gray(ogIMG);
        finalIMG = rgb2gray(finalIMG);
        diffIMG = imabsdiff(ogIMG,finalIMG);
        mse = immse(finalIMG, ogIMG);
        psnr = 20 * log10(255/sqrt(mse));
        subplot(3,3,7),imagesc(diffIMG);
        colorbar;
    end
end

