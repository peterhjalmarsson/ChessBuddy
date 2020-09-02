/* 
 * File:   chessboard.h
 * Author: peter
 *
 * Created on May 14, 2013, 10:44 AM
 * 
 * A chess board representation with a move generator.
 * It can also be used as a very basic search engine,
 * mainly for suggesting moves. Playing strength is
 * most likely very weak.
 * 12*12 board representation (mail box).
 * It does not handle moves beyond 250.
 */

#ifndef CHESSBOARD_H
#define	CHESSBOARD_H

#include "tcl.h"
#include "movegenerator.h"
#include <string>
extern "C" 
{
    int Chessboard_Init(Tcl_Interp *interp);  

    long getMilliSec();

#define TCL_ARG ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]

static int setBoard(TCL_ARG);
static int currentMoves(TCL_ARG);
static int perft(TCL_ARG);
static int divide(TCL_ARG);
static int printBoard(TCL_ARG);
static int positionString(TCL_ARG);
static int canReachSquare(TCL_ARG);
static int move(TCL_ARG);
static int ownPiece(TCL_ARG);
static int getMove(TCL_ARG);
static int moveNumber(TCL_ARG);
static int startPos(TCL_ARG);
static int uciToFormat(TCL_ARG);
static int lose(TCL_ARG);
static int book(TCL_ARG);
}

bool makeUciMove(std::string move, MoveGenerator *movegen, int listEnd,Board *b);
bool draw(bool color, bool strict);
Move moveFromBook(int pos);

#endif	/* CHESSBOARD_H */

