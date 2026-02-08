#ifndef GAMECHEAT_STOCKFISH_BRIDGE_H
#define GAMECHEAT_STOCKFISH_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int gc_stockfish_bestmove(const char* fen,
                          int32_t skill_level,
                          int32_t move_time_ms,
                          char* out_move,
                          int32_t out_move_capacity);

#ifdef __cplusplus
}
#endif

#endif
