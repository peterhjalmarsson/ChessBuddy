/* 
 * File:   board.h
 * Author: peter
 *
 * Created on May 14, 2013, 1:36 AM
 */

#ifndef BOARD_H
#define	BOARD_H

#include <string>
#include <vector>
#include "move.h"

//extern const char OFF_BOARD[144];
//extern const std::string START_FEN;

/*flag is not used, just there to make size 64 bit instead of 56.*/
struct Position {
    U64 key;
    Move move;
    uchar castle;
    uchar halfMove;
    schar enPassant;
    uchar flag;
};

extern const uchar CASTLE_WQ;
extern const uchar CASTLE_WK;
extern const uchar CASTLE_BQ;
extern const uchar CASTLE_BK;

enum MoveString {UCI,SAN,LONG,COMPLETE};

struct Book {
    U64 key;	
    ushort move;
    ushort weight;
    uint learn;
};

class Board {
public:
    std::vector<Book> book;
    std::vector<Book>::iterator bookMove[100];
    bool startpos;
    std::string startFen;
    int startMove;
    std::string fen;
    Board();
    Board(const Board& orig);
    virtual ~Board();
    void positionFromFen(std::string fenIn);
    std::string fenFromPosition();
    void startPosition();
    void makeMove(Move move);
    void unmakeMove();
    void printBoard();
    int currentPosition;
    Position position[500];
    Piece square[144];
    inline bool colorToMove(){
        return (currentPosition&1);
    }
    Square whiteKing;
    Square blackKing;
    std::string moveToString(MoveString type, Move move);
    int repetition();
    inline Square enemyKing(){
        return colorToMove() ? whiteKing:blackKing;
    };
    inline Square ownKing(){
        return colorToMove() ? blackKing:whiteKing;
    };
    inline Position* currPos(){
        return &position[currentPosition];
    };
    void openBook(std::string file);
    void closeBook();
    void getEntry();
private:
    void updateCastle(Square square);
    std::string moveToLongNotation(Move move);
    std::string moveToSan(Move move);
    std::string moveToCompleteString(Move move);
    std::string moveToUci(Move move);
    U64 hash();
    void checkCastle();
};

#endif	/* BOARD_H */

