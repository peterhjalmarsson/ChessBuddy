/* 
 * File:   MoveGenerator.cpp
 * Author: peter
 * 
 * Created on May 14, 2013, 4:24 PM
 */

#include <iostream>
#include "movegenerator.h"

MoveGenerator::MoveGenerator(Board *board) {
    board_ = board;
}

MoveGenerator::~MoveGenerator() {
}
/*offsets for all pieces but pawns*/
const int OFFSET[5][8] = {
    {-25, -23, -14, -10, 10, 14, 23, 25},
    {-13, -11, 11, 13, 0, 0, 0, 0},
    {-12, -1, 1, 12, 0, 0, 0, 0},
    {-13, -12, -11, -1, 1, 11, 12, 13},
    {-13, -12, -11, -1, 1, 11, 12, 13}
};

int MoveGenerator::generate(int pos) {
    illegal = false;
    currentPos_ = pos;
    startPos_=pos;
    /*browse through all squares to find own pieces*/
    for (int file = 2; file < 10; file++) {
        for (int rank = 24; rank < 120; rank += 12) {
            int pos = file + rank;
            Piece piece = board_->square[pos];
            if (piece == NO_PIECE)
                continue;
            if (getPieceColor(piece) != board_->colorToMove())
                continue;
            piece = removeColor(piece);
            if (piece == P) {
                /*white and black pawns are handled separately*/
                if (board_->colorToMove() == WHITE_BOOL) {
                    if (board_->square[pos + 12] == NO_PIECE) {
                        Move m = {P,NO_PIECE,NO_PIECE, (Square) pos, (Square) (pos + 12), 0,ID_OK};
                        if (pos > H6) {
                            addPromotionMove(m);
                        } else {
                            addMove(m);
                            if (pos < A3 && board_->square[pos + 24] == NO_PIECE) {
                                m.to = (Square) (pos + 24);
                                m.type = DOUBLE_STEP;
                                addMove(m);
                            }
                        }
                    }
                    int enPassant = board_->position[board_->currentPosition].enPassant + A6;
                    if (!OFF_BOARD[pos + 11]) {
                        if (pieceIsColor(board_->square[pos + 11], !board_->colorToMove())) {
                            Move m = {P,board_->square[pos + 11],NO_PIECE, (Square) pos, (Square) (pos + 11), 0,ID_OK};
                            if (pos > H6) {
                                addPromotionMove(m);
                            } else {
                                addMove(m);
                            }
                        } else if (pos + 11 == enPassant) {
                            Move m = {P,NO_PIECE,NO_PIECE, (Square) pos, (Square) (pos + 11), EN_PASSANT,ID_OK};
                            addMove(m);
                        }
                    }
                    if (!OFF_BOARD[pos + 13]) {
                        if (pieceIsColor(board_->square[pos + 13], !board_->colorToMove())) {
                            Move m = {P,board_->square[pos + 13],NO_PIECE, (Square) pos, (Square) (pos + 13), 0,ID_OK};
                            if (pos > H6) {
                                addPromotionMove(m);
                            } else {
                                addMove(m);
                            }
                        } else if (pos + 13 == enPassant) {
                            Move m = {P,NO_PIECE,NO_PIECE, (Square) pos, (Square) (pos + 13), EN_PASSANT,ID_OK};
                            addMove(m);
                        }
                    }
                } else { //black
                    if (board_->square[pos - 12] == NO_PIECE) {
                        Move m = {P,NO_PIECE,NO_PIECE, (Square) pos, (Square) (pos - 12), 0,ID_OK};
                        if (pos < A3) {
                            addPromotionMove(m);
                        } else {
                            addMove(m);
                            if (pos > H6 && board_->square[pos - 24] == NO_PIECE) {
                                m.to = (Square) (pos - 24);
                                m.type = DOUBLE_STEP;
                                addMove(m);
                            }
                        }
                    }
                    int enPassant = board_->position[board_->currentPosition].enPassant + A3;
                    if (!OFF_BOARD[pos - 11]) {
                        if (pieceIsColor(board_->square[pos - 11], !board_->colorToMove())) {
                            Move m = {P,board_->square[pos - 11],NO_PIECE, (Square) pos, (Square) (pos - 11), 0,ID_OK};
                            if (pos < A3) {
                                addPromotionMove(m);
                            } else {
                                addMove(m);
                            }
                        } else if (pos - 11 == enPassant) {
                            Move m = {P,NO_PIECE,NO_PIECE, (Square) pos, (Square) (pos - 11), EN_PASSANT,ID_OK};
                            addMove(m);
                        }
                    }
                    if (!OFF_BOARD[pos - 13]) {
                        if (pieceIsColor(board_->square[pos - 13], !board_->colorToMove())) {
                            Move m = {P,board_->square[pos - 13],NO_PIECE, (Square) pos, (Square) (pos - 13), 0,ID_OK};
                            if (pos < A3) {
                                addPromotionMove(m);
                            } else {
                                addMove(m);
                            }
                        } else if (pos - 13 == enPassant) {
                            Move m = {P,NO_PIECE,NO_PIECE, (Square) pos, (Square) (pos - 13), EN_PASSANT,ID_OK};
                            addMove(m);
                        }
                    }
                }
            } else {
                for (int i = 0; i < 8; i++) {
                    if (OFFSET[piece - 2][i] == 0)
                        break;
                    int offset = 0;
                    while (true) {
                        offset += OFFSET[piece - 2][i];
                        if (OFF_BOARD[pos + offset] || pieceIsColor(board_->square[pos + offset], board_->colorToMove()))
                            break;
                        Move m = {piece,board_->square[pos + offset],NO_PIECE, (Square) pos, (Square) (pos + offset), 0,ID_OK};
                        addMove(m);
                        if (board_->square[pos + offset] != NO_PIECE)
                            break;
                        if (piece < B || piece > Q)
                            break;
                    }
                }
            }
        }
    }
    /*castling*/
    if (board_->colorToMove() == WHITE_BOOL) {
        if (board_->position[board_->currentPosition].castle & CASTLE_WK
                && board_->square[F1] == NO_PIECE
                && board_->square[G1] == NO_PIECE
                && !enemyAttackSquare(NO_MOVE, E1)
                && !enemyAttackSquare(NO_MOVE, F1)) {
            Move m = {K,NO_PIECE,NO_PIECE, E1, G1, CASTLE_K,ID_OK};
            addMove(m);
        }
        if (board_->position[board_->currentPosition].castle & CASTLE_WQ
                && board_->square[D1] == NO_PIECE
                && board_->square[C1] == NO_PIECE
                && board_->square[B1] == NO_PIECE
                && !enemyAttackSquare(NO_MOVE, E1)
                && !enemyAttackSquare(NO_MOVE, D1)) {
            Move m = {K,NO_PIECE,NO_PIECE, E1, C1, CASTLE_Q,ID_OK};
            addMove(m);
        }
    } else {
        if (board_->position[board_->currentPosition].castle & CASTLE_BK
                && board_->square[F8] == NO_PIECE
                && board_->square[G8] == NO_PIECE
                && !enemyAttackSquare(NO_MOVE, E8)
                && !enemyAttackSquare(NO_MOVE, F8)) {
            Move m = {K,NO_PIECE,NO_PIECE, E8, G8, CASTLE_K,ID_OK};
            addMove(m);
        }
        if (board_->position[board_->currentPosition].castle & CASTLE_BQ
                && board_->square[D8] == NO_PIECE
                && board_->square[C8] == NO_PIECE
                && board_->square[B8] == NO_PIECE
                && !enemyAttackSquare(NO_MOVE, E8)
                && !enemyAttackSquare(NO_MOVE, D8)) {
            Move m = {K,NO_PIECE,NO_PIECE, E8, C8, CASTLE_Q,ID_OK};
            addMove(m);
        }
    }
    checkDoubles();
    return currentPos_;
}
void MoveGenerator::checkDoubles(){
    for (int i=startPos_;i<currentPos_;i++){
        for (int j=i+1;j<currentPos_;j++){
            if(moveList[i].to==moveList[j].to && moveList[i].from!=moveList[j].from
                    && board_->square[moveList[i].from]==board_->square[moveList[j].from]){
                if(file(moveList[i].from)!=file(moveList[j].from)){
                    moveList[i].id=(moveList[i].id==ID_OK) ? ID_FILE:ID_BOTH;
                    moveList[j].id=(moveList[j].id==ID_OK) ? ID_FILE:ID_BOTH;
                } else {
                    moveList[i].id=(moveList[i].id==ID_OK) ? ID_RANK:ID_BOTH;
                    moveList[j].id=(moveList[j].id==ID_OK) ? ID_RANK:ID_BOTH;
                }
            }
        }
    } 
}

void MoveGenerator::addMove(Move move) {
    assert(move.capPiece==NO_PIECE 
            || getPieceColor(move.capPiece)!=getPieceColor(board_->square[move.from]));
    /*king is moving*/
    if (move.from == board_->ownKing()) {
        if (!enemyAttackSquare(move, move.to)) {
            if (moveIsChecking(move))
                move.type |= CHECK;
            moveList[currentPos_++] = move;
        }
    } else if (!enemyAttackSquare(move, board_->ownKing())) {
        if (moveIsChecking(move))
            move.type |= CHECK;
        moveList[currentPos_++] = move;
    }
}

void MoveGenerator::addPromotionMove(Move move) {
    for (int piece = Q; piece >P; piece--) {
        move.promPiece=(Piece) piece;
        addMove(move);
    }
}

bool MoveGenerator::moveIsChecking(Move move) {
    Piece piece = removeColor(board_->square[move.from]);
    if(move.promPiece!=NO_PIECE)
        piece=move.promPiece;
    Square king = board_->enemyKing();
    if (piece == P) {
        if (board_->colorToMove() == WHITE_BOOL) {
            if (move.to + 11 == king)
                return true;
            if (move.to + 13 == king)
                return true;
        } else {
            if (move.to - 11 == king)
                return true;
            if (move.to - 13 == king)
                return true;
        }
    } else if (piece == N) {
        for (int i = 0; i < 8; i++) {
            if (move.to + OFFSET[0][i] == king)
                return true;
        }
    }
    if (piece == B || piece == Q) {
        int d = diagonal(move.to, king);
//        std::cout<<board_->moveToString(LONG, move)<<" diagonal is "<<d
//                <<" from "<<squareToString(move.to)<<" to "<<squareToString(king)<<std::endl;
        if (d != 0) {
            int offset = 0;
            while (true) {
                offset += d;
                if (OFF_BOARD[move.to + offset])
                    break;
                if (board_->square[move.to + offset] != NO_PIECE) {
                    if (move.to + offset == king)
                        return true;
                    break;
                }
            }
        }
    }
    if (piece == R || piece == Q) {
        int l = line(move.to, king);
        if (l != 0) {
            int offset = 0;
            while (true) {
                offset += l;
                if (OFF_BOARD[move.to + offset])
                    break;
                if (board_->square[move.to + offset] != NO_PIECE) {
                    if (move.to + offset == king)
                        return true;
                    break;
                }
            }
        }
    }
    /*discovered check, bishop and queen*/
    int d = diagonal(king, move.from);
    if (d != 0) {
        int offset = 0;
        while (true) {
            offset += d;
            if (OFF_BOARD[king + offset])
                break;
            Piece p = board_->square[king + offset];
            if(king+offset==move.to)
                p=piece;
            if (p != NO_PIECE && king + offset != move.from) {
                if (board_->colorToMove() == WHITE_BOOL) {
                    if (p == WB || p == WQ)
                        return true;
                } else {
                    if (p == BB || p == BQ)
                        return true;
                }
                break;
            }
        }
    }
    /*discovered check rook and queen*/
    int l = line(king, move.from);
    if (l != 0) {
        int offset = 0;
        while (true) {
            offset += l;
            if (OFF_BOARD[king + offset])
                break;
            Piece p = board_->square[king + offset];
            if(king+offset==move.to)
                p=piece;
            if (p != NO_PIECE && king + offset != move.from) {
                if (board_->colorToMove() == WHITE_BOOL) {
                    if (p == WR || p == WQ) {
                        return true;
                    }
                } else {
                    if (p == BR || p == BQ) {
                        return true;
                    }
                }
                break;
            }
        }
    }
    return false;
}

/*returns 0 if not on a diagonal*/
int MoveGenerator::diagonal(Square from, Square to) {
    if ((from - to) % 13 == 0) {
        if (from < to && from % 12 < to % 12)
            return 13;
        if (from > to && from % 12 > to % 12)
            return -13;
    } else if ((from - to) % 11 == 0) {
        if (from < to && from % 12 > to % 12)
            return 11;
        if (from > to && from % 12 < to % 12)
            return -11;
    }
    return 0;
}

/*return 0 if not on a line*/
int MoveGenerator::line(Square from, Square to) {
    if (from < to) {
        if (to - from < 8)
            return 1;
        if ((to - from) % 12 == 0)
            return 12;
    } else {
        if ((from - to) < 8)
            return -1;
        if ((from - to) % 12 == 0)
            return -12;
    }
    return 0;
}

bool MoveGenerator::enemyAttackSquare(Move move, Square square) {
    board_->makeMove(move);
    bool attack = false;
    if (board_->colorToMove() == BLACK_BOOL) {
        if (board_->square[square + 11] == BP)
            attack = true;
        else if (board_->square[square + 13] == BP)
            attack = true;
        for (int i = 0; i < 8; i++) {
            if (board_->square[square + OFFSET[0][i]] == BN)
                attack = true;
        }
        for (int i = 0; i < 8; i++) {
            if (board_->square[square + OFFSET[4][i]] == BK)
                attack = true;
        }
        for (int i = 0; i < 4; i++) {
            int offset = 0;
            while (true) {
                offset += OFFSET[1][i];
                if (OFF_BOARD[square + offset])
                    break;
                Piece p = board_->square[square + offset];
                if (p != NO_PIECE) {
                    if (p == BB || p == BQ)
                        attack = true;
                    break;
                }
            }
        }
        for (int i = 0; i < 4; i++) {
            int offset = 0;
            while (true) {
                offset += OFFSET[2][i];
                if (OFF_BOARD[square + offset])
                    break;
                Piece p = board_->square[square + offset];
                if (p != NO_PIECE) {
                    if (p == BR || p == BQ)
                        attack = true;
                    break;
                }
            }
        }
    } else {
        if (board_->square[square - 11] == WP)
            attack = true;
        else if (board_->square[square - 13] == WP)
            attack = true;
        for (int i = 0; i < 8; i++) {
            if (board_->square[square + OFFSET[0][i]] == WN)
                attack = true;
        }
        for (int i = 0; i < 8; i++) {
            if (board_->square[square + OFFSET[4][i]] == WK)
                attack = true;
        }
        for (int i = 0; i < 4; i++) {
            int offset = 0;
            while (true) {
                offset += OFFSET[1][i];
                if (OFF_BOARD[square + offset])
                    break;
                Piece p = board_->square[square + offset];
                if (p != NO_PIECE) {
                    if (p == WB || p == WQ)
                        attack = true;
                    break;
                }
            }
        }
        for (int i = 0; i < 4; i++) {
            int offset = 0;
            while (true) {
                offset += OFFSET[2][i];
                if (OFF_BOARD[square + offset])
                    break;
                Piece p = board_->square[square + offset];
                if (p != NO_PIECE) {
                    if (p == WR || p == WQ)
                        attack = true;
                    break;
                }
            }
        }
    }
    board_->unmakeMove();
    return attack;
}

