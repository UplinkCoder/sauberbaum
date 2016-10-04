module sauerbaum;
/*
      N  
  NW     NO
w           O    
  SW     SO
      S
*/
static immutable sauerbaum_layoutString = "x x x x x x x\n" ~ "             \n" ~ "      x      \n" ~ "             \n" ~ "      x      \n" ~ "x x x x x x x\n" ~ " x x x x x x \n" ~ "  x x x x x  \n" ~ "   x x x x   \n" ~ "   x x x x   \n" ~ "    x x x    \n" ~ "     x x     \n" ~ "      o      ";

struct SauerBaum
{
    enum xmax = int(13);
    enum ymax = int(16);

    SauerbaumFieldType[ymax * xmax] sauerbaumGrid = parseSauerbaum(
`      x       
     x x     
    x x x    
   x x x x   
  x x x x x  
   x x x x   
    x x x    
   x x x x   
  x x x x x  
 x x x x x x 
x x x x x x x
      x      
             
      x      
             
x x x x x x x`)
        .sauerbaumGrid;
    uint[8] playerPositions = [0, 2, 4, 6, 8, 10, 12];
    uint players = void;
    //StartField is {0,7}
    //Players Start at [{0,0}, {0,12}]
    //Special turnaroundField is {3,7}

    /// x and y are not zero based
    SauerbaumFieldType* position(int x, int y) pure
    {
        if ((x == 0 || y == 0) || (x > xmax || y > ymax))
            assert(0, "Invalid Value for x and y");
        else
            return &sauerbaumGrid[((x - 1) * ymax + (y - 1))];
    }

    enum startFieldIndex = 6;
    enum turnaroundFieldIndex = 5 * 14 + 6;
    uint dropsRemaining = 30;
    static bool isSpecialTurnaroundField(uint index) pure
    {
        return index == turnaroundFieldIndex;
    }

    void addDrop()
    {
        if (dropsRemaining)
        {
            --dropsRemaining;
            foreach_reverse (ref f; sauerbaumGrid)
            {
                if (f == SauerbaumFieldType.Free)
                {
                    f = SauerbaumFieldType.RainDrop;
                    break;
                  }
            }
        }
        else
        {
            SauerbaumFieldType* rainField = null;
            foreach_reverse (ref f; sauerbaumGrid)
            {
                if (rainField)
                {
                    if (f == SauerbaumFieldType.Free)
                    {
                        f = SauerbaumFieldType.RainDrop;
                        *rainField = SauerbaumFieldType.Free;
                        break;
                    }
                    continue;
                }
                else if (f == SauerbaumFieldType.RainDrop)
                {
                    rainField = &f;
                }
            }
        }
    }

    /*    uint[DirectionsEnum.max*3] canMoveTo(uint steps)
    {
        foreach(direction;directions)
        {
          dest
        }
    }
*/
}

import std.string;

enum Direction
{
    Invalid,

    North,
    NorthEast,
    East,
    SouthEast,
    South,
    SouthWest,
    West,
    NorthWest,
}

enum SauerbaumFieldType : ubyte
{
    Invalid,
    Free,
    RainDrop,
    Player1,
    Player2,
    Player3,
    Player4,
    Player5,
    Player6,
    Player7,
}

SauerBaum parseSauerbaum(string sauerbaum, bool reversed = false)
{
    SauerbaumFieldType[SauerBaum.xmax * SauerBaum.ymax] sb = SauerbaumFieldType.Invalid;
    uint[8] pp = 0;

    foreach (linen, line; sauerbaum.splitLines)
    {
        foreach (coln, char c; line)
        {
            immutable idx = reversed ? linen * SauerBaum.xmax + coln : (
                SauerBaum.ymax - 1 - linen) * SauerBaum.xmax + (SauerBaum.xmax - 1 - coln);
            if (c == 'x')
            {
                sb[idx] = SauerbaumFieldType.Free;
            }
            else if (c == 'o')
            {
                sb[idx] = SauerbaumFieldType.RainDrop;
            }
            else if (c >= '1' && c <= '7')
            {
                sb[idx] = cast(SauerbaumFieldType)(SauerbaumFieldType.Player1 + (c - '1'));
            }
        }
    }

    return SauerBaum(sb, pp);
}

debug
{
    string validPositionString(SauerBaum sb)
    {
        string result;
        import std.conv;

        foreach (i, f; sb.sauerbaumGrid)
        {
            if (f == SauerbaumFieldType.Free)
            {
                result ~= "x: " ~ (i % (sb.xmax)).to!string ~ ", y: " ~ (i / sb.xmax)
                    .to!string ~ "\n";
            }
        }
        return result;
    }

    pragma(msg, validPositionString(SauerBaum.init));
}

string drawSauerbaum(SauerBaum sb)
{
    char[] result;
    int oldy;

    foreach (uint i, f; sb.sauerbaumGrid)
    {
        if ((i / sb.xmax) != oldy)
        {
            result ~= "\n";
            oldy = (i / sb.xmax);
        }

        final switch (f) with (SauerbaumFieldType)
        {
        case Invalid:
            result ~= " ";
            break;
        case Free:
            result ~= "x";
            break;
        case RainDrop:
            result ~= "o";
            break;
        case Player1:
            result ~= "1";
            break;
        case Player2:
            result ~= "2";
            break;
        case Player3:
            result ~= "3";
            break;
        case Player4:
            result ~= "4";
            break;
        case Player5:
            result ~= "5";
            break;
        case Player6:
            result ~= "6";
            break;
        case Player7:
            result ~= "7";
            break;
        }
    }

    import std.algorithm : reverse;

    reverse(result);
    return cast(string) result;
}

string Rain()
{
    SauerBaum sb;
    string result;

    foreach (_; 0 .. 40)
    {
        result ~= "\n-----------------\n";
        sb.addDrop();
        result ~= drawSauerbaum(sb);
        result ~= "\n-----------------";
    }

    return result;
}
pragma(msg, Rain());

struct GameState
{
    SauerBaum sb;
//    DrawState ds;
    uint players()
    {
        return sb.players;
    }

    void rain(uint n)
    {
        while(n--) sb.addDrop();
    }

    bool won()
    {
        return true;
    }

    bool lost()
    {
        return false;
    }

    uint castDice()
    {
        // use reproduceable rng here
        return 3;
    }

    void beginDrawMovementDice()
    {
    }

    void endDrawMovementDice()
    {
        
    }

    void drawMovementDice(uint diceFace)
    {
    }

    uint choseDice()
    {
        //TODO this has to be implemented!
        return 0;
    }

    void showRainDice(uint diceFace)
    {
    }

    Path[] calculatePaths(uint playerIndex, uint stepCount)
    {
        assert(playerIndex >= 0 && playerIndex <= 6);
        return [];
    }

    uint choseDestination(Path[] destinations)
    {
        return 0;
    }

    void removeDrop(uint playerIndex, SauerbaumFieldType* drop)
    {
        assert(playerIndex >= 0 && playerIndex <= 6);
        // TODO show animation of flying raindrop
    }

    void movePlayer(uint playerIndex, Path p)
    {
        assert(playerIndex >= 0 && playerIndex <= 6);
        sb.sauerbaumGrid[sb.playerPositions[playerIndex]] = SauerbaumFieldType.Free;
        *p.dest = cast(SauerbaumFieldType) (SauerbaumFieldType.Player1 + playerIndex);
    }
}

struct Path
{
    SauerbaumFieldType* dest;
}

GameState beginGame(uint nPlayers = 7, uint nRainDrops = 40)
{
    SauerBaum sb;
    assert(nPlayers >= 3 && nPlayers <= 7, "Invalid number of players");
    assert(nRainDrops >= 30 && nRainDrops <= 60, "Invalid number of Raindrops");
    sb.players = nPlayers;
    sb.dropsRemaining = nRainDrops;
    sb.addDrop();

    return GameState(sb);
}

void Game()
{
    auto gameState = beginGame(7); // beginGameWith 7 players;

    with (gameState)
    {

        while (!won && !lost)
        {
            foreach (pi; 0 .. gameState.players)
            {

                auto rainDice = castDice();
                showRainDice(rainDice);
                rain(rainDice);
                uint[3] movementDice = [castDice(), castDice(), castDice()];
                uint diceRemaining = 3;
            LdrawMovementDice:
                {
                    beginDrawMovementDice;

                    foreach (dice; movementDice)
                    {
                        if (dice != 0)
                        {
                            drawMovementDice(dice);
                        }
                    }

                    endDrawMovementDice();
                }

                auto diceIndex = choseDice();
                diceRemaining--;
                auto paths = calculatePaths(pi, movementDice[diceIndex]);
                auto destIndex = choseDestination(paths);
                if (*(paths[destIndex].dest) == SauerbaumFieldType.RainDrop)
                {
                    removeDrop(pi, paths[destIndex].dest);
                }
                movePlayer(pi, paths[destIndex]);
                if (diceRemaining)
                    goto LdrawMovementDice;
            }
        }

    }
}
