#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>   // for atoi()
#include <string.h>   // for strcpy(), sprintf()
//.Wav file
typedef struct {
    char     riff[4];        // RIFF
    uint32_t fileSize; 
    char     wave[4];        // WAVE 
    char     fmt[4];         // fmt  
    uint32_t fmtLength;      // Length of the format data based on the format chunk marker = 16.
    uint16_t audioFormat;    // PCM = 1 
    uint16_t numChannels;    // Number of audio channels = 1 for monophonic audio
    uint32_t sampleRate;     // Sampling rate of the saved audio = 6400 
    uint32_t byteRate;       // Bytes per second of the saved audio = (6400*16*1)/8 
    uint16_t blockAlign;     // Bytes per sample per channel of the saved audio = (16*1)/8 
    uint16_t bitsPerSample;  // Bits per sample = 16 
    char     data[4];        // data 
    uint32_t dataSize;       // The total size of the DATA in bytes EXCLUDING the 44 byte header = 50000 
} WavHeader;

int main(int argc, char *argv[])
{
    char input_txt[150]; // Filename for input text/binary file
    char output_wav[150]; // Filename for output WAV file
    uint32_t fs = 6400; // Default sample rate
    // Get team ID and sample rate from command line arguments
    if (argc >= 3) {
        char *team_id = argv[1];
        char *fs_str = argv[2];
        fs = (uint32_t)atoi(fs_str); // Convert string to number
        // Create filenames using team ID and sample rate
        sprintf(input_txt, "recorded_audio_%s_%s.txt", team_id, fs_str);
        sprintf(output_wav, "recorded_audio_%s_%s.wav", team_id, fs_str);
    } else {
        // Default filenames if no arguments provided
        strcpy(input_txt, "raw_ADC_values.txt");
        strcpy(output_wav, "recorded_audio.wav");
    }
    // Open input file (raw audio data) and output WAV file
    FILE *binPtr = fopen(input_txt, "rb"); 
    FILE *wavPtr = fopen(output_wav, "wb");
    if (binPtr == NULL || wavPtr == NULL) {
        printf("Error opening files\n"); 
        return 1;
    }
    // ================================================
    // Get the size of the raw audio data file
    // ================================================
    fseek(binPtr, 0, SEEK_END); //point to the end , 0 means shifting 0 bits to left
    long raw_filesize = ftell(binPtr); // Get current position (file size)
    fseek(binPtr, 0, SEEK_SET); // Put the pointer to the first in case that can't read anything
    // ================================================
    // Create and fill the WAV file header
    // ================================================
    WavHeader header = 
    {
        .riff = {'R', 'I', 'F', 'F'},
        .fileSize = (uint32_t)(raw_filesize + 44 - 8), // 8 is riff[4] and filesize 4 bytes
        .wave = {'W', 'A', 'V', 'E'},
        .fmt = {'f', 'm', 't', ' '},
        .fmtLength = 16,
        .audioFormat = 1,
        .numChannels = 1,
        .sampleRate = fs,
        .byteRate = fs*2,   
        .blockAlign = 2,     
        .bitsPerSample = 16,
        .data = {'d', 'a', 't', 'a'},
        .dataSize = (uint32_t)(raw_filesize)
    };
    // Write the 44-byte WAV header to the output file
    fwrite(&header, sizeof(WavHeader), 1, wavPtr); // write header
    // ================================================
    // Convert raw ADC data to proper 16-bit WAV audio
    // ================================================
    uint16_t rawData; // Value read from .txt file (0 to 4095)
    int16_t scaledData; // Final signed 16-bit value for WAV
    int res = fread(&rawData, sizeof(uint16_t), 1, binPtr); // Read first value
    // Process all samples in the file
    while (res == 1 && !feof(binPtr)) 
    {
        // Scale from 12-bit ADC range (0-4095) to signed 16-bit range (-32768 to 32767)
        scaledData = (int16_t)((rawData / 4095.0 * 65535.0) - 32768.0);
        fwrite(&scaledData, sizeof(int16_t), 1, wavPtr); // Write to WAV file
        res = fread(&rawData, sizeof(uint16_t), 1, binPtr); // Read next value
    }
    fclose(binPtr);
    fclose(wavPtr);
    return 0;
}
