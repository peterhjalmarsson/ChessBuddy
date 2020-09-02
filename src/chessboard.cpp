
#include "chessboard.h"
#include "board.h"
#include "movegenerator.h"
#include <iostream>
#include <stdlib.h>
#include <sstream>

Board *board;
MoveGenerator *movegen;
int listEnd;

int Chessboard_Init(Tcl_Interp *interp) {
    board = new Board();
    movegen = new MoveGenerator(board);
    listEnd = movegen->generate(0);
    //std::cout<<"init gen "<<listEnd<<std::endl;
    Tcl_Namespace *nsPtr;
    if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
        return TCL_ERROR;
    }
    /* create namespace */
    nsPtr = Tcl_CreateNamespace(interp, "libboard", NULL, NULL);
    if (nsPtr == NULL) {
        return TCL_ERROR;
    }
    Tcl_PkgProvide(interp, "Board", "1.0");
    Tcl_CreateObjCommand(interp, "libboard::setboard", setBoard, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::currentmoves", currentMoves, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::perft", perft, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::divide", divide, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::printboard", printBoard, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::position", positionString, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::canreachsquare", canReachSquare, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::move", move, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::ownpiece", ownPiece, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::getmove", getMove, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::movenumber", moveNumber, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::startpos", startPos, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::ucitoformat", uciToFormat, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::lose", lose, NULL, NULL);
    Tcl_CreateObjCommand(interp, "libboard::book", book, NULL, NULL);
    return TCL_OK;
}

static int setBoard(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    /*called with no arguments will set up start position*/
    if (objc < 2) {
        board->startPosition();
    } else {
        std::string firstArg(objv[1]->bytes);
        if (firstArg == "startpos") {
            board->startPosition();
            ;
        } else if (firstArg == "fen") {
            if (objc < 3)
                std::cerr << "Error: Missing fen string.\n" <<
                    "Should be [ board::setboard fen <fen string> ]" << std::endl;
            std::string fen = "";
            for (int i = 2; i < objc; i++) {
                std::string arg(objv[i]->bytes);
                fen += arg + " ";
            }
            board->positionFromFen(fen);
        } else {
            std::cerr << "Error: " << firstArg << " is not a valid argument." << std::endl;
            return TCL_ERROR;
        }
    }
    listEnd = movegen->generate(0);
    //std::cout<<"setboard gen "<<listEnd<<std::endl;
    return TCL_OK;
}

static int currentMoves(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    std::string moves = "";
    if (objc < 2)
        for (int i = 0; i < listEnd; i++)
            moves += board->moveToString(LONG, movegen->moveList[i]) + " ";
    else {
        std::string firstArg(objv[1]->bytes);
        if (firstArg == "long")
            for (int i = 0; i < listEnd; i++)
                moves += board->moveToString(LONG, movegen->moveList[i]) + " ";
        else if (firstArg == "complete")
            for (int i = 0; i < listEnd; i++)
                moves += "\"" + board->moveToString(COMPLETE, movegen->moveList[i]) + "\" ";
        else if (firstArg == "uci")
            for (int i = 0; i < listEnd; i++)
                moves += board->moveToString(UCI, movegen->moveList[i]) + " ";
        else if (firstArg == "san")
            for (int i = 0; i < listEnd; i++)
                moves += board->moveToString(SAN, movegen->moveList[i]) + " ";
    }
    Tcl_SetObjResult(interp, Tcl_NewStringObj(moves.c_str(), -1));
    return TCL_OK;
}

int perft(int start, int depth) {
    int count = 0;
    if (depth <= 0)
        return 1;
    int end = movegen->generate(start);
    //std::cout<<"perft gen "<<end<<std::endl;
    for (int i = start; i < end; i++) {
        //        std::cout<<depth<<" "<<(i-start+1)
        //                <<" "<<board->moveToLongNotation(movegen->moveList[i])<<std::endl;
        board->makeMove(movegen->moveList[i]);
        //board->printBoard();
        count += perft(end, depth - 1);
        board->unmakeMove();
    }
    return count;
}

static int perft(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    long time = getMilliSec();
    std::cout << time << std::endl;
    int depth = atoi(objv[1]->bytes);
    int result = perft(0, depth);
    time = getMilliSec() - time;
    std::cout << time << std::endl;
    std::string str = "nodes ";
    std::stringstream ss;
    ss << result;
    str += ss.str();
    str += " time ";
    ss.str("");
    ss.clear();
    ss << time;
    str += ss.str();
    str += " knps ";
    ss.str("");
    ss.clear();
    ss << (result / time);
    str += ss.str();
    Tcl_SetObjResult(interp, Tcl_NewStringObj(str.c_str(), -1));
    return TCL_OK;
}

static int divide(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    int depth = atoi(objv[1]->bytes);
    int count = 0;
    if (depth <= 0)
        return 1;
    int end = movegen->generate(0);
    //std::cout<<"divide gen "<<end<<std::endl;
    for (int i = 0; i < end; i++) {
        board->makeMove(movegen->moveList[i]);
        int pCount = perft(end, depth - 1);
        std::cout << depth << " " << board->moveToString(LONG, movegen->moveList[i]) << " " << pCount << std::endl;
        count += pCount;
        board->unmakeMove();
    }
    std::stringstream ss;
    ss << count;
    std::string str = ss.str();
    Tcl_SetObjResult(interp, Tcl_NewStringObj(str.c_str(), -1));
    return TCL_OK;
}

long getMilliSec() {
    struct timespec time;
    clock_gettime(CLOCK_REALTIME, &time);
    return time.tv_sec * 1000 + time.tv_nsec / 1000000;
}

static int printBoard(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    board->printBoard();
    return TCL_OK;
}

static int positionString(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    if (objc < 2)
        return TCL_ERROR;
    std::string firstArg(objv[1]->bytes);
    if (firstArg == "result") {
        std::string res = "";
        std::string type = "";
        if (movegen->generate(0) == 0) {
            if (!board->position[board->currentPosition].move.check()) {
                res = "1/2-1/2";
                type = "Draw by stalemate.";
            } else if (board->colorToMove()) {
                res = "1-0";
                type = "White mates.";
            } else {
                res = "0-1";
                type = "Black mates.";
            }
        } else if (draw(false, false) && draw(true, false)) {
            res = "1/2-1/2";
            type = "Draw by insufficent material.";
        }
        if (board->position[board->currentPosition].halfMove > 99) {
            res = "1/2-1/2";
            type = "Draw by 50 moves rule.";
        }
        if (board->repetition() > 2) {
            res = "1/2-1/2";
            type = "Draw by repetition.";
        }
        if (board->currentPosition >= 500) {
            res = "1/2-1/2";
            type = "Draw by 250 moves rule.";
        }
        if (res != "") {
            Tcl_SetObjResult(interp, Tcl_NewStringObj(res.c_str(), -1));
            Tcl_Obj *lResult;
            lResult = Tcl_GetObjResult(interp);
            Tcl_Obj *poStr;
            poStr = Tcl_NewStringObj(type.c_str(), -1);
            Tcl_ListObjAppendElement(interp, lResult, poStr);
        }
    } else if (firstArg == "color") {
        std::string str = "white";
        if (board->colorToMove())
            str = "black";
        Tcl_SetObjResult(interp, Tcl_NewStringObj(str.c_str(), -1));
    } else if (firstArg == "oppcolor") {
        std::string str = "black";
        if (board->colorToMove())
            str = "white";
        Tcl_SetObjResult(interp, Tcl_NewStringObj(str.c_str(), -1));
    } else if (firstArg == "single") {
        std::string str = "";
        for (int i = 24; i < 120; i += 12)
            for (int j = 2; j < 10; j++)
                str += pieceToString(board->square[i + j]);
        Tcl_SetObjResult(interp, Tcl_NewStringObj(str.c_str(), -1));
    } else if (firstArg == "uci") {
        std::string str = "";
        if (board->startpos)
            str = "position startpos ";
        else
            str = "position fen " + board->startFen;
        if (board->currentPosition > board->startMove) {
            str += " moves ";
            for (int i = board->startMove + 1; i <= board->currentPosition; i++)
                str += board->moveToString(UCI, board->position[i].move) + " ";
        }
        Tcl_SetObjResult(interp, Tcl_NewStringObj(str.c_str(), -1));
    } else if (firstArg == "pieces") {
        std::string secondArg(objv[2]->bytes);
        int pcount[6] = {0, 0, 0, 0, 0, 0};
        for (int rank = 24; rank < 120; rank += 12) {
            for (int file = 2; file < 10; file++) {
                Piece p = board->square[rank + file];
                if (p == NO_PIECE)
                    continue;
                if (p < BP)
                    pcount[p - 1]++;
                else
                    pcount[p - 9]--;
            }
        }
        std::string result = "";
        std::string plist = "543210";
        if (secondArg == "white") {
            for (int i = 4; i >= 0; i--) {
                int j = pcount[i];
                while (j > 0) {
                    result += plist[i];
                    result += " ";
                    j--;
                }
            }
        } else if (secondArg == "black") {
            for (int i = 4; i >= 0; i--) {
                int j = pcount[i];
                while (j < 0) {
                    result += plist[i];
                    result += " ";
                    j++;
                }
            }
        }
        Tcl_SetObjResult(interp, Tcl_NewStringObj(result.c_str(), -1));
    }
    return TCL_OK;
}

static int canReachSquare(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    if (objc < 2)
        return TCL_ERROR;
    if(objv[1]->bytes == nullptr)
    return TCL_OK;
    Square s = numberToSquare(objv[1]->bytes);
    std::string list = "";
    for (int i = 0; i < listEnd; i++) {
        if (movegen->moveList[i].from == s) {
            //            std::cout<<squareToString(movegen->moveList[i].from)
            //                    <<squareToString(movegen->moveList[i].to)<<std::endl;
            list += squareToNumber(movegen->moveList[i].to) + " ";
        } else if (movegen->moveList[i].to == s) {
            //            std::cout<<squareToString(movegen->moveList[i].from)
            //                    <<squareToString(movegen->moveList[i].to)<<std::endl;
            list += squareToNumber(movegen->moveList[i].from) + " ";
        }
    }
    Tcl_SetObjResult(interp, Tcl_NewStringObj(list.c_str(), -1));
    return TCL_OK;
}

static int move(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    if (objc < 2)
        return TCL_ERROR;
    std::string firstArg(objv[1]->bytes);
    if (firstArg == "back") {
        board->unmakeMove();
        listEnd = movegen->generate(0);
        //std::cout<<"move1 gen "<<listEnd<<std::endl;
    } else if (firstArg == "uci") {
        if (objc < 3)
            return TCL_ERROR;
        std::string move(objv[2]->bytes);
        if (!makeUciMove(move, movegen, listEnd, board))
            return TCL_ERROR;
        listEnd = movegen->generate(0);
        //std::cout<<"move2 gen "<<move<<" "<<listEnd<<std::endl;
        //board->printBoard();
    } else if (firstArg == "san") {
        if (objc < 3)
            return TCL_ERROR;
        std::string move(objv[2]->bytes);
        Piece prom = NO_PIECE;
        Piece own = P;
        Square to = NO_SQUARE;
        bool toOk = false;
        int fromRank = 0;
        int fromFile = 0;
        for (int i = move.length(); i >= 0; i--) {
            if (move[i] == '#') continue;
            if (move[i] == '+') continue;
            if (move[i] == 'x') continue;
            std::string str = "ZPNBRQK";
            std::size_t pos = str.find_first_of(move[i]);
            if (pos != std::string::npos) {
                if (!toOk)
                    prom = (Piece) pos;
                else
                    own = (Piece) pos;
            }
            str = "12345678";
            pos = str.find_first_of(move[i]);
            if (pos != std::string::npos) {
                if (!toOk)
                    to = (Square) (12 * pos + 24);
                else
                    fromRank = pos + 2;
            }
            str = "abcdefgh";
            pos = str.find_first_of(move[i]);
            if (pos != std::string::npos) {
                if (!toOk) {
                    to = (Square) (to + pos + 2);
                    toOk = true;
                } else
                    fromFile = pos + 2;
            }
        }
        //std::cout<<"move to "<<to<<" own piece "<<own<<std::endl;
        for (int i = 0; i < listEnd; i++) {
            if (move == "O-O" || move == "o-o") {
                if (movegen->moveList[i].castleKing()) {
                    board->makeMove(movegen->moveList[i]);
                    listEnd = movegen->generate(0);
                    //std::cout<<"move3 gen "<<listEnd<<std::endl;
                    break;
                }
            } else if (move == "O-O-O" || move == "o-o-o") {
                if (movegen->moveList[i].castleQueen()) {
                    board->makeMove(movegen->moveList[i]);
                    listEnd = movegen->generate(0);
                    //std::cout<<"move4 gen "<<listEnd<<std::endl;
                    break;
                }
            } else if (movegen->moveList[i].to == to
                    && movegen->moveList[i].ownPiece == own) {
                //std::cout<<"found "<<board->moveToString(SAN,movegen->moveList[i])<<std::endl;
                if (fromFile > 0 && fromFile != movegen->moveList[i].from % 12)
                    continue;
                //std::cout<<fromFile<<" found2 "<<board->moveToString(SAN,movegen->moveList[i])<<std::endl;
                if (fromRank > 0 && fromRank != movegen->moveList[i].from / 12)
                    continue;
                //std::cout<<fromRank<<" found3 "<<board->moveToString(SAN,movegen->moveList[i])<<std::endl;
                if (prom != movegen->moveList[i].promPiece)
                    continue;
                board->makeMove(movegen->moveList[i]);
                listEnd = movegen->generate(0);
                //std::cout<<"move5 gen "<<listEnd<<std::endl;
                break;
            }
        }
    } else if (firstArg == "unsorted") {
        if (objc < 4)
            return TCL_ERROR;
        std::string move1(objv[2]->bytes);
        std::string move2(objv[3]->bytes);
        for (int i = 0; i < listEnd; i++) {
            if (movegen->moveList[i].from == numberToSquare(move1)
                    && movegen->moveList[i].to == numberToSquare(move2)) {
                board->makeMove(movegen->moveList[i]);
                listEnd = movegen->generate(0);
                //std::cout<<"move6 gen "<<listEnd<<std::endl;
                break;
            } else if (movegen->moveList[i].from == numberToSquare(move2)
                    && movegen->moveList[i].to == numberToSquare(move1)) {
                board->makeMove(movegen->moveList[i]);
                listEnd = movegen->generate(0);
                //std::cout<<"move7 gen "<<listEnd<<std::endl;
                break;
            }
        }
    } else {
        return TCL_ERROR;
    }
    std::string str = board->moveToString(UCI, board->position[board->currentPosition].move);
    Tcl_SetObjResult(interp, Tcl_NewStringObj(str.c_str(), -1));
    return TCL_OK;
}

bool makeUciMove(std::string move, MoveGenerator *gen, int end, Board *b) {
    std::string from = move.substr(0, 2);
    std::string to = move.substr(2, 2);
    Piece prom = NO_PIECE;
    if (move.length() > 4) {
        std::string p = "--nbrqNBRQ";
        size_t pos = p.find_first_of(move[4]);
        if (pos != std::string::npos) {
            if (pos > 5)
                pos -= 4;
            prom = (Piece) pos;
        }
    }
    for (int i = 0; i < end; i++) {
        if (move == "O-O" || move == "o-o") {
            if (movegen->moveList[i].castleKing()) {
                board->makeMove(movegen->moveList[i]);
                listEnd = movegen->generate(0);
                //std::cout<<"move3 gen "<<listEnd<<std::endl;
                break;
            }
        } else if (move == "O-O-O" || move == "o-o-o") {
            if (movegen->moveList[i].castleQueen()) {
                board->makeMove(movegen->moveList[i]);
                listEnd = movegen->generate(0);
                //std::cout<<"move4 gen "<<listEnd<<std::endl;
                break;
            }
        }
        if (gen->moveList[i].from == stringToSquare(from)
                && gen->moveList[i].to == stringToSquare(to)
                /*some engines don't give any promotion piece at all, use queen*/
                && (prom == gen->moveList[i].promPiece 
                    || (gen->moveList[i].promPiece==5 && prom ==0))
           ) {
            b->makeMove(gen->moveList[i]);
            return true;
        }
    }
    return false;
}

static int ownPiece(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    if (objc < 2)
        return TCL_ERROR;
    std::string result = "false";
    if (pieceIsColor(board->square[stringToSquare(objv[1]->bytes)], board->colorToMove()))
        result = "true";
    Tcl_SetObjResult(interp, Tcl_NewStringObj(result.c_str(), -1));
    return TCL_OK;
}

static int getMove(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    if (objc < 2)
        return TCL_ERROR;
    std::string firstArg(objv[1]->bytes);
    bool number = false;
    MoveString mStr = UCI;
    for (int i = 2; i < objc; i++) {
        std::string arg = std::string(objv[i]->bytes);
        if (arg == "number")
            number = true;
        else if (arg == "long")
            mStr = LONG;
        else if (arg == "complete")
            mStr = COMPLETE;
        else if (arg == "san")
            mStr = SAN;
    }
    std::string result = "";
    if (firstArg == "current") {
        if (number && (board->currentPosition & 1)) {
            char n[4];
            sprintf(n, "%d", board->currentPosition / 2 + 1);
            result += n;
            result += ".";
        }
        result += board->moveToString(mStr, board->position[board->currentPosition].move);
    } else if (firstArg == "all") {
        for (int i = board->startMove + 1; i <= board->currentPosition; i++) {
            if (number && (i & 1)) {
                char n[4];
                sprintf(n, "%d", i / 2 + 1);
                result += n;
                result += ".";
            }
            result += board->moveToString(mStr, board->position[i].move) + " ";
        }
    } else if (firstArg == "pos") {
        if (objc < 3)
            return TCL_ERROR;
        int pos = atoi(objv[2]->bytes);
        if (number && (pos & 1)) {
            char n[4];
            sprintf(n, "%d", pos / 2 + 1);
            result += n;
            result += ".";
        }
        result += board->moveToString(mStr, board->position[pos].move);
    }
    Tcl_SetObjResult(interp, Tcl_NewStringObj(result.c_str(), -1));
    return TCL_OK;
}

static int moveNumber(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    if (objc < 2)
        return TCL_ERROR;
    std::string firstArg(objv[1]->bytes);
    char n[4];
    if (firstArg == "current")
        sprintf(n, "%d", board->currentPosition);
    if (firstArg == "start")
        sprintf(n, "%d", board->startMove);
    Tcl_SetObjResult(interp, Tcl_NewStringObj(n, -1));
    return TCL_OK;
}

static int startPos(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    std::string result;
    if (board->startpos)
        result = "startpos";
    else
        result = board->startFen;
    Tcl_SetObjResult(interp, Tcl_NewStringObj(result.c_str(), -1));
    return TCL_OK;
}

static int uciToFormat(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    if (objc < 2)
        return TCL_ERROR;
    //for(int i=0;i<objc;i++){
    //    std::string arg=std::string(objv[i]->bytes);
    //    std::cout<<arg<<" ";
    //}
    //std::cout<<objc<<std::endl;
    Board *b = new Board();
    //board->printBoard();
    // std::cout<<board->fen<<std::endl;
    b->positionFromFen(board->fen);
    //b->printBoard();
    MoveGenerator *gen = new MoveGenerator(b);
    bool number = false;
    MoveString mStr = SAN;
    int pos = 3;
    for (int i = 1; i < 3; i++) {
        std::string arg = std::string(objv[i]->bytes);
        if (arg == "number")
            number = true;
        else if (arg == "long")
            mStr = LONG;
        else if (arg == "san")
            mStr = SAN;
        else {
            pos = i;
            break;
        }
    }
    std::string result = "";
    //    if(number && (board->currentPosition&1)){ 
    //        char n[4];
    //        sprintf(n,"%d",board->currentPosition/2+1);
    //        result+=n;
    //        result+=".";
    //    }
    //std::cout<<"pv count"<<pos<<" "<<objc<<std::endl;
    for (int i = pos; i < objc; i++) {
        std::string move(objv[i]->bytes);
        int end = gen->generate(0);
        //std::cout<<"uci gen "<<end<<std::endl;
        if (!makeUciMove(move, gen, end, b)) {
            //for (int p=0;p<end;p++)
            //    std::cout<<b->moveToString(UCI,gen->moveList[p])<<" ";
            //std::cout<<"BREAK  "<<move<<"  ";
            break;
        }
        if (i > pos)
            result += " ";
        if (number && (b->currentPosition & 1)) {
            char n[4];
            sprintf(n, "%d", b->currentPosition / 2 + 1);
            result += n;
            result += ".";
        }
        result += b->moveToString(mStr, b->position[b->currentPosition].move);
        //std::cout<<b->moveToString(mStr,b->position[b->currentPosition].move)<<" MOVE    ";
    }
    std::string str = "";
    for (int i = 24; i < 120; i += 12)
        for (int j = 2; j < 10; j++)
            str += pieceToString(b->square[i + j]);
    result = str + " " + result;
    //    for(int i=0;i<count;i++){
    //        board->unmakeMove();
    //    }
    //    listEnd=gen->generate(0);
    delete b;
    delete gen;
    Tcl_SetObjResult(interp, Tcl_NewStringObj(result.c_str(), -1));
    return TCL_OK;
}

static int lose(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    if (objc < 2)
        return TCL_ERROR;
    std::string firstArg(objv[1]->bytes);
    int count = 0;
    std::string result = "1/2-1/2";
    bool color = BLACK_BOOL;
    if (firstArg == "white")
        color = WHITE_BOOL;
    if (!draw(color, true))
        result = color ? "1-0" : "0-1";
    Tcl_SetObjResult(interp, Tcl_NewStringObj(result.c_str(), -1));
    return TCL_OK;
}

bool draw(bool color, bool strict) {
    int count = 0;
    for (int i = 2; i < 10; i++) {
        for (int j = 24; j < 120; j += 12) {
            Piece p = board->square[i + j];
            if (p == NO_PIECE) continue;
            if (pieceIsColor(p, color)) continue;
            p = removeColor(p);
            if (p == K) continue;
            if (p == N) count += 2;
            else if (p == B) count += 3;
            else if (p >= P) {
                return false;
            }
            if (strict && count > 2)
                return false;
            if (count > 4)
                return false;
        }
    }
    return true;
}

static int book(ClientData cdata, Tcl_Interp *interp, int objc, Tcl_Obj * const objv[]) {
    if (objc < 2)
        return TCL_ERROR;
    std::string firstArg(objv[1]->bytes);
    if (firstArg == "open") {
        if (objc < 3)
            return TCL_ERROR;
        std::string file(objv[2]->bytes);
        board->openBook(file);
        return TCL_OK;
    }
    if (firstArg == "close") {
        board->closeBook();
        return TCL_OK;
    }
    if (firstArg == "move") {
        if (objc < 4)
            return TCL_ERROR;
        std::string typeStr(objv[2]->bytes);
        MoveString type = UCI;
        if (typeStr == "long")
            type = LONG;
        else if (typeStr == "complete")
            type = COMPLETE;
        else if (typeStr == "uci")
            type = UCI;
        else if (typeStr == "san")
            type = UCI;
        board->getEntry();
        if (board->bookMove[0] == (std::vector<Book>::iterator)(0)){
            return TCL_OK;
        }   
        listEnd = movegen->generate(0);
        std::string result = "";
        std::string sel(objv[3]->bytes);
        if (sel == "all") {
            for (int i = 0; board->bookMove[i] != (std::vector<Book>::iterator)(0); i++) {
                Move m=moveFromBook(i);
                result += board->moveToString(type, m) + " ";
                std::stringstream ss;
                ss << board->bookMove[i]->weight;
                result += ss.str() + " ";
            }
            Tcl_SetObjResult(interp, Tcl_NewStringObj(result.c_str(), -1));
            return TCL_OK;
        } else if (sel == "best"){
            int count=1;
            /*this relies on moves being sorted by score, if edited after creation this might not be true*/
            for (int i = 1; board->bookMove[i] != (std::vector<Book>::iterator)(0); i++) {
                if (board->bookMove[i]->weight < board->bookMove[0]->weight)
                    break;
                count++;
            }
            int pos=0;
            if(count>1){
                srand(clock());
                pos=rand()%count;   
            }
            std::string result = board->moveToString(type, moveFromBook(pos));
            Tcl_SetObjResult(interp, Tcl_NewStringObj(result.c_str(), -1));
            return TCL_OK;
        } else if (sel == "random"){
            int total=0;
            for (int i = 0; board->bookMove[i] != (std::vector<Book>::iterator)(0); i++) {
                total+=board->bookMove[i]->weight;
            }
            srand(clock());
            int num=rand()%total;
            total=0;
            int i=0;
            while (board->bookMove[i] != (std::vector<Book>::iterator)(0)) {
                total+=board->bookMove[i]->weight;
                if(num<total)
                    break;
                i++;
            }
            std::string result = board->moveToString(type, moveFromBook(i));
            Tcl_SetObjResult(interp, Tcl_NewStringObj(result.c_str(), -1));
            return TCL_OK;
        }
    }
}

Move moveFromBook(int pos){
    for (int i = 0; i < listEnd; i++) {
        Square to = (Square) ((board->bookMove[pos]->move & 7) + 12 * ((board->bookMove[pos]->move >> 3)&7) + 26);
        Square from = (Square) (((board->bookMove[pos]->move >> 6)&7) + 12 * ((board->bookMove[pos]->move >> 9)&7) + 26);
        Piece prom = (Piece) ((board->bookMove[pos]->move >> 12)&7);
        if (movegen->moveList[i].from == from
                && movegen->moveList[i].to == to
                && movegen->moveList[i].promPiece == prom)
            return movegen->moveList[i];
    }
    return NO_MOVE;
}
