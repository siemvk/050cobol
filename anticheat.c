#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void AntiCheatService(char *lk_score, char *lk_check, char *lk_valid) {
    lk_valid[0] = 'N';

    if (!lk_score || !lk_check) return;

    char score[32] = {0};
    char check[128] = {0};

    int s_len = 0;
    while (lk_score[s_len] != ' ' && lk_score[s_len] != '\0' && lk_score[s_len] != '\r' && lk_score[s_len] != '\n' && s_len < 30) {
        score[s_len] = lk_score[s_len];
        s_len++;
    }
    score[s_len] = '\0';

    int c_len = 0;
    while (lk_check[c_len] != ' ' && lk_check[c_len] != '\0' && lk_check[c_len] != '\r' && lk_check[c_len] != '\n' && c_len < 120) {
        check[c_len] = lk_check[c_len];
        c_len++;
    }
    check[c_len] = '\0';

    if (s_len == 0 || c_len == 0) return;

    long score_val = atol(score);
    if (score_val < 0 || score_val > 10000) return;

    // Unshift check by -3 to get base64
    char b64[128] = {0};
    for (int i = 0; i < c_len; i++) {
        b64[i] = (char)((unsigned char)check[i] - 3);
    }
    b64[c_len] = '\0';

    static const int b64_index[256] = {
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,
        52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-1,-1,-1,
        -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,
        15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,
        -1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
        41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1
    };

    char decoded[128] = {0};
    int out_len = 0;
    int val = 0, valb = -8;
    for (int i = 0; i < c_len; i++) {
        unsigned char c = (unsigned char)b64[i];
        if (c == '=') break;
        if (b64_index[c] == -1) continue;
        val = (val << 6) + b64_index[c];
        valb += 6;
        if (valb >= 0) {
            decoded[out_len++] = (char)((val >> valb) & 0xFF);
            valb -= 8;
        }
    }
    decoded[out_len] = '\0';

    if (strcmp(decoded, score) == 0) {
        lk_valid[0] = 'Y';
    }
}
