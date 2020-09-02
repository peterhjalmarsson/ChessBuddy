/* 
 * File:   piece.h
 * Author: peter
 *
 * Created on May 14, 2013, 1:27 AM
 */

#ifndef PIECE_H
#define	PIECE_H
#include "definitions.h"
#include <assert.h>

enum Piece {
    NO_PIECE = 0,
    P = 1, N = 2, B = 3, R = 4, Q = 5, K = 6,
    WP = 1, WN = 2, WB = 3, WR = 4, WQ = 5, WK = 6,
    BP = 9, BN = 10, BB = 11, BR = 12, BQ = 13, BK = 14
};

const bool WHITE_BOOL=false;
const bool BLACK_BOOL=true;

inline bool getPieceColor(Piece piece){
    assert(piece!=NO_PIECE);
    return (piece&8);
};

inline Piece removeColor(Piece piece){
    return (Piece)(piece&7);
};
/*remember: NO_PIECE always return false
 ie !pieceIsColor(p,c) is not the same as pieceIsColor(p,!c)*/
inline bool pieceIsColor(Piece piece, bool color){
    if(piece==NO_PIECE)
        return false;
    return getPieceColor(piece)==color;
};

inline std::string pieceToString(Piece piece){
    const std::string pStr="-PNBRQKXxpnbrqkx";
    return pStr.substr(piece,1);
}


#endif	/* PIECE_H */

