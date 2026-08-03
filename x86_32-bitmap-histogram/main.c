#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#pragma pack(push, 1)
typedef struct {
    uint16_t type;
    uint32_t size;
    uint16_t reserved1;
    uint16_t reserved2;
    uint32_t offset;
} BMPHeader;

typedef struct {
    uint32_t size;
    int32_t width;
    int32_t height;
    uint16_t planes;
    uint16_t bits;
    uint32_t compression;
    uint32_t imagesize;
    int32_t xresolution;
    int32_t yresolution;
    uint32_t ncolours;
    uint32_t importantcolours;
} BMPInfoHeader;
#pragma pack(pop)

extern void histogram(void *img, uint32_t width, uint32_t height, void *hist);

uint8_t* read_bmp(const char* filename, uint32_t* width, uint32_t* height) {
    FILE* file = fopen(filename, "rb");
    if (!file) {
        printf("Error: Cannot open file %s\n", filename);
        return NULL;
    }

    BMPHeader header;
    BMPInfoHeader info;

    //read header
    fread(&header, sizeof(BMPHeader), 1, file);
    if (header.type != 0x4D42) { // "BM"
        printf("Error: Not a valid BMP file\n");
        fclose(file);
        return NULL;
    }

    //read info header
    fread(&info, sizeof(BMPInfoHeader), 1, file);
    if (info.bits != 8) {
        printf("Error: Only 8-bit BMP files are supported\n");
        fclose(file);
        return NULL;
    }

    *width = info.width;
    *height = abs(info.height);
    
    //skip color palette (256 colors * 4 bytes each)
    fseek(file, header.offset, SEEK_SET);

    //calculate padding
    uint32_t row_padded = ((*width) + 3) & (~3);
    uint32_t data_size = row_padded * (*height);

    uint8_t* img_data = malloc(data_size);
    if (!img_data) {
        printf("Error: Memory allocation failed\n");
        fclose(file);
        return NULL;
    }

    //read img data
    fread(img_data, 1, data_size, file);
    fclose(file);

    return img_data;
}


void write_histogram_bmp(const char* filename, uint32_t* hist_data) {
    FILE* file = fopen(filename, "wb");
    if (!file) {
        printf("Error: Cannot create output file\n");
        return;
    }

    //create 256x256 image data (initialized to black)
    uint8_t* img_data = calloc(256 * 256, 1);
    
    //draw histogram columns
    for (int x = 0; x < 256; x++) {
        uint32_t pixel_count = hist_data[x];
        uint32_t column_height;
        
        //>256 pixels, make column full height
        //else actual pixel count as column height
        if (pixel_count > 256) {
            column_height = 256;
        } else {
            column_height = pixel_count;
        }
        
        for (uint32_t y = 0; y < column_height; y++) {
            img_data[y * 256 + x] = 255; //white pixels for histogram
        }
    }

    //write headers
    BMPHeader header = {0};
    header.type = 0x4D42; // "BM"
    header.size = sizeof(BMPHeader) + sizeof(BMPInfoHeader) + 256 * 4 + 256 * 256;
    header.offset = sizeof(BMPHeader) + sizeof(BMPInfoHeader) + 256 * 4;

    BMPInfoHeader info = {0};
    info.size = sizeof(BMPInfoHeader);
    info.width = 256;
    info.height = 256;
    info.planes = 1;
    info.bits = 8;
    info.imagesize = 256 * 256;
    info.ncolours = 256;

    fwrite(&header, sizeof(BMPHeader), 1, file);
    fwrite(&info, sizeof(BMPInfoHeader), 1, file);

    //write grayscale palette
    for (int i = 0; i < 256; i++) {
        uint8_t color[4] = {i, i, i, 0};
        fwrite(color, 4, 1, file);
    }

    //write img data
    fwrite(img_data, 256 * 256, 1, file);

    free(img_data);
    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Usage: %s <input.bmp>\n", argv[0]);
        return 1;
    }

    uint32_t width, height;
    uint8_t* img_data = read_bmp(argv[1], &width, &height);
    if (!img_data) {
        return 1;
    }
    //reading colour pallete
    FILE* f = fopen(argv[1], "rb");
    fseek(f, sizeof(BMPHeader) + sizeof(BMPInfoHeader), SEEK_SET);
    uint8_t palette[256][4]; // BGRA
    fread(palette, sizeof(uint8_t), 1024, f); 
    fclose(f);

    printf("Loaded BMP: %dx%d pixels\n", width, height);

    //allocate and initialize histogram array to zeros
    uint32_t* hist_data = calloc(256, sizeof(uint32_t));

    histogram(img_data, width, height, hist_data);
    //output show
    printf("Histogram values:\n");
    for (int i = 0; i < 256; i++) {
    uint8_t b = palette[i][0];
    uint8_t g = palette[i][1];
    uint8_t r = palette[i][2];
    printf("Index %3d: %7u pixels | RGB(%3d, %3d, %3d)\n", i, hist_data[i], r, g, b);
    }

    //write histogram as BMP
    write_histogram_bmp("hist.bmp", hist_data);
    printf("Histogram saved as hist.bmp\n");
    printf("Note: Bars with >256 pixels are shown at full height (256 pixels)\n");

    free(img_data);
    free(hist_data);
    return 0;
}