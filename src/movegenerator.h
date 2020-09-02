/* 
 * File:   MoveGenerator.h
 * Author: peter
 *
 * Created on May 14, 2013, 4:24 PM
 * 
 * Move generator which generates legal moves.
 * It is designed to be simple rather than fast.
 * The way illegal moves are detected is very straightforward
 * and not very efficient.
 * It also detects if a move is checking, in the same inefficient
 * way.
 */

#ifndef MOVEGENERATOR_H
#define	MOVEGENERATOR_H

#include "board.h"

class MoveGenerator {
public:
    MoveGenerator(Board *board);
    virtual ~MoveGenerator();
    int generate(int pos);
    bool illegal;
    Move moveList[1000];
private:
    Board *board_;
    int currentPos_;
    int startPos_;
    
    void checkDoubles();
    void addMove(Move move);
    void addPromotionMove(Move move);
    bool moveIsChecking(Move move);
    bool enemyAttackSquare(Move move,Square square);
    int diagonal(Square from, Square to);
    int line(Square from, Square to);
};

#endif	/* MOVEGENERATOR_H */

