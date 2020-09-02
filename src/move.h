/* 
 * File:   move.h
 * Author: peter
 *
 * Created on May 14, 2013, 12:58 AM
 */

#ifndef MOVE_H
#define	MOVE_H

#include "definitions.h"
#include "piece.h"
#include "square.h"

/*type bits:
 1:en passant
 2:pawn double step
 3:castle king side
 4:castle queen side
 5:check*/
const uchar EN_PASSANT=1;
const uchar DOUBLE_STEP=2;
const uchar CASTLE_K=4;
const uchar CASTLE_Q=8;
const uchar CHECK=16;

enum IdentifyMove {ID_OK,ID_FILE,ID_RANK,ID_BOTH};

struct Move {
    Piece ownPiece;
    Piece capPiece;
    Piece promPiece;
    Square from;
    Square to;
    uchar type;
    IdentifyMove id;

    bool enPassant() {
        return type & 1;
    }

   bool doubleStep() {
        return type & 2;
    }

    bool castleKing() {
        return type & 4;
    }

    bool castleQueen() {
        return type & 8;
    }

    bool castle() {
        return type & 12;
    }

    bool check() {
        return type & 16;
    }
};

const Move NO_MOVE = {NO_PIECE,NO_PIECE,NO_PIECE, (Square)0, (Square)0, 0,ID_OK};

#endif	/* MOVE_H */

