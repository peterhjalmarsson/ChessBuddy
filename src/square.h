/* 
 * File:   square.h
 * Author: peter
 *
 * Created on May 14, 2013, 4:42 PM
 */

#ifndef SQUARE_H
#define	SQUARE_H

#include <sstream>
#include <stdlib.h>

enum Square {
    A1=26,B1=27,C1=28,D1=29,E1=30,F1=31,G1=32,H1=33,
    A2=38,B2=39,C2=40,D2=41,E2=42,F2=43,G2=44,H2=45,
    A3=50,B3=51,C3=52,D3=53,E3=54,F3=55,G3=56,H3=57,
    A4=62,B4=63,C4=64,D4=65,E4=66,F4=67,G4=68,H4=69,
    A5=74,B5=75,C5=76,D5=77,E5=78,F5=79,G5=80,H5=81,
    A6=86,B6=87,C6=88,D6=89,E6=90,F6=31,G6=92,H6=93,
    A7=98,B7=99,C7=100,D7=101,E7=102,F7=103,G7=104,H7=105,
    A8=110,B8=111,C8=112,D8=113,E8=114,F8=115,G8=116,H8=117,
    NO_SQUARE=145
};

const char OFF_BOARD[144] = {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
};

inline uchar file(Square square){
    return square%12-2;
}

inline uchar rank(Square square){
    return square/12-2;
}

inline std::string squareToString(Square square){
    std::string str="  ";
    str[0]=(file(square)+'a');
    str[1]=(rank(square)+'1');
    return str;
}

inline Square stringToSquare(std::string str){
    int s=str[0]-'a'+2;
    s+=12*(str[1]-'1'+2);
    return (Square)s;
}

inline std::string squareToNumber(Square sqr){
    int n = 8*(sqr/12-2)+(sqr%12-2);
    std::stringstream ss;
    ss<<n;
    std::string str= ss.str();
    return str;
}

inline Square numberToSquare(std::string sqr){
    int s=atoi((sqr.c_str()));
    return (Square)(12*(s/8+2)+(s%8+2));
}

#endif	/* SQUARE_H */

