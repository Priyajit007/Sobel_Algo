module image_read();
parameter sizeOfWidth = 8;   // data width
parameter sizeOfLengthReal = 307200; //total data bytes
parameter INFILE  = "D:/Coding/MATLAB/testPic.hex";
parameter OUTFILE  = "D:/Coding/MATLAB/testPicOut.hex";
reg [7 : 0]   total_memory [0 : sizeOfLengthReal-1];// memory to store  8-bit data image
reg [7:0] temp_BMP [0 :sizeOfLengthReal-1]; // Temp memory to store memory
wire read=1;
wire write=1;
initial begin
    $readmemh(INFILE,total_memory,0,sizeOfLengthReal-1); // read file from INFILE
end

// Test Code------------
integer i=0;
initial begin
    for(i=0; i<sizeOfLengthReal;i=i+1)
    if(i<sizeOfLengthReal) begin
       temp_BMP[i] = total_memory[i]; 
    end
end

//---------------------Sobel Algo Here

initial begin
    $writememh(OUTFILE,temp_BMP,0,sizeOfLengthReal-1); // Write file to OUTFILE
end

endmodule
