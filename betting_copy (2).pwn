#include < fdialog >
#include < YSI_Coding\y_hooks >
#include < YSI_Data\y_foreach >

#define d_BINGO										7879
#define d_BINGO_BET									7880

#define BINGO_COUNTDOWN_RING_FLASH					// mijenjanje boja prstena naizmjenicno pri countdownu

static bool:g_sIsBingoDrawStarted;
static g_sBingoCountdown;
static g_sBingoStep;

static Iterator:BingoNumbers<48>;					// iterator koji cuva zauzete/izvucene brojeve
static Iterator:BingoPlayer<MAX_PLAYERS>;			// iterator za igrace koji koriste bingo
static g_sBingoNumbers[MAX_PLAYERS][6];				// cuva upisane brojeve igraca
static g_sBingoPayout[MAX_PLAYERS];					// cuva kolicinu novca za isplatu, nepotrebno ako zelis da igrac
													// dobija novac odmah nakon sto pogodi 6 brojeva
static g_sBingoTrueNumbers[MAX_PLAYERS];			// cuva broj pogodjenih brojeva
static g_sBingoBet[MAX_PLAYERS];					// cuva ulog
static g_sBingoBusinessID[MAX_PLAYERS]; 			// cuva id firme u kojoj je pokrenut bingo, nepotrebno ako ne zelis da skidas
													// firmi novac koji igrac dobije

new Text:BingoGeneral_TD[71]; // global textdrawovi
new Text:BingoBigNumber_TD; // global textdraw countdowna, takodje prikazuje izvuceni broj
new Text:BingoNumbers_TD[35]; // izvuceni brojevi
new PlayerText:BingoMyNumbers_PTD[MAX_PLAYERS]; // player textdraw koji prikazuje igraceve brojeve koje upise u dialog

#include "betting_td.pwn"

static Bingo_CreateTextDraws() {
	// ....
}

static Player_ShowBingoTextDraws(playerid) {
	// create + show
	// ....
}

static Player_HideBingoTextDraws(playerid) {
	// destroy
	// ....
}

static Player_StartBingo(playerid) {
	if (Iter_Contains(BingoPlayer, playerid)) Player_StopBingo(playerid);

	Iter_Add(BingoPlayer, playerid);

	new string[20];

	format(string, sizeof string,
		"%d %d %d %d %d %d",
		g_sBingoNumbers[playerid][0],
		g_sBingoNumbers[playerid][1],
		g_sBingoNumbers[playerid][2],
		g_sBingoNumbers[playerid][3],
		g_sBingoNumbers[playerid][4],
		g_sBingoNumbers[playerid][5]
	);

	PlayerTextDrawSetString(playerid, BingoMyNumbers_PTD[playerid], string);
	Player_ShowBingoTextDraws(playerid);

	SendClientMessage(playerid, 0x75ffbaff, "Da sklonite chat pritisnite 'F7' par puta.");
	return 1;
}

static Player_StopBingo(playerid, bool:remove_iter = true) {
	if (remove_iter) Iter_Remove(BingoPlayer, playerid);

	Player_HideBingoTextDraws(playerid);

	if (g_sBingoPayout[playerid] != 0) {
		g_NovacPlus(playerid, g_sBingoPayout[playerid]);

		g_sBingoPayout[playerid] = 0;
	}
	return 1;
}

static Player_IsPlayingBingo(playerid) {
	return Iter_Contains(BingoPlayer, playerid);
}

static Bingo_GetQuoteByStep(step) {
	switch(step) {
	case 30: return 1;
	case 29: return 2;
	case 28: return 3;
	case 27: return 4;
	case 26: return 5;
	case 25: return 6;
	case 24: return 7;
	case 23: return 8;
	case 22: return 9;
	case 21: return 10;
	case 19: return 15;
	case 18: return 20;
	case 17: return 25;
	case 16: return 30;
	case 15: return 35;
	case 14: return 40;
	case 13: return 45;
	case 12: return 50;
	case 11: return 55;
	case 10: return 60;
	case 9: return 65;
	case 8: return 70;
	case 7: return 75;
	case 6: return 80;
	case 5: return 85;
	case 4: return 90;
	case 3: return 95;
	case 2: return 100;
	case 1: return 200;
	case 0: return 300;
	default: return 0;
	}
	return 0;
}

forward timer_BingoDraw();
public timer_BingoDraw() {
	static buffer[4];

	if (g_sIsBingoDrawStarted) {
		new number = Iter_RandomFree(BingoNumbers) + 1, step = (++ g_sBingoStep);

		Iter_Add(BingoNumbers, number - 1);

		if (!(step >= sizeof BingoNumbers_TD)) {
			new j = 0;
			
			SAMP_valstr(buffer, number);
			TextDrawSetString(BingoBigNumber_TD, buffer);
			TextDrawSetString(BingoNumbers_TD[step], buffer);

			#if defined BINGO_COUNTDOWN_RING_FLASH
				TextDrawColor(BingoGeneral_TD[2], random(0xffffffff) & ~0xFF | 255);
			#endif

			foreach(new i : BingoPlayer) {
				#if defined BINGO_COUNTDOWN_RING_FLASH
					TextDrawShowForPlayer(i, BingoGeneral_TD[2]);
				#endif

				for(j = 0; j < 6; j ++) {
					if (g_sBingoNumbers[i][j] == number) {
						g_sBingoNumbers[i][j] = 100;

						if ((++ g_sBingoTrueNumbers[i]) >= 6 && step > 5) {
							new payoff = g_sBingoPayout[i] = Bingo_GetQuoteByStep(step - 5) * g_sBingoBet[i];

							if (payoff != 0) {
								va_PlayerTextDrawSetString(i, BingoMyNumbers_PTD[i], "Cestitamo! Dobili ste ~g~%d$~w~~h~~h~.", payoff);
								Business_GiveMoney(g_sBingoBusinessID[i], -payoff);
							}
						}
					}
				}

				if (step == 35) {
					GameTextForPlayer(i, "Bingo zavrsen~n~Prozorcic se zatvara za 8 sekundi.~n~Da prikazete chat - F7", 4000, 3);
				}
			}
		}
		else if (step >= sizeof BingoNumbers_TD + 8) {
			g_sBingoCountdown = 200;
			g_sIsBingoDrawStarted = false;

			TextDrawSetString(BingoBigNumber_TD, "200");

			for(new i = sizeof BingoNumbers_TD - 1; i >= 0; i --) TextDrawSetString(BingoNumbers_TD[i], " ");
			Iter_Clear(BingoNumbers);

			foreach(new i : BingoPlayer) {
				Player_StopBingo(i, false);
				Iter_SafeRemove(BingoPlayer, i, i);
			}
		}
	}
	else {
		new countdown = (-- g_sBingoCountdown);

		valstr(buffer, countdown);
		TextDrawSetString(BingoBigNumber_TD, buffer);

		#if defined BINGO_COUNTDOWN_RING_FLASH
			TextDrawColor(BingoGeneral_TD[2], random(0xffffffff) & ~0xFF | 255);
			foreach(new i : BingoPlayer) {
				TextDrawShowForPlayer(i, BingoGeneral_TD[2]);
			}	
		#endif

		if (!countdown) {
			g_sIsBingoDrawStarted = true;

			Iter_Clear(BingoNumbers);
		}
		g_sBingoStep = -1;
	}
	return 1;
}

hook OnGameModeInit() {
	g_sIsBingoDrawStarted = false;
	g_sBingoCountdown = 500;

	SetTimer("timer_BingoDraw", 1000, true);

	Bingo_CreateTextDraws();
	return 1;
}

hook OnPlayerDisconnect(playerid, reason) {
	#pragma unused reason
	
	if (Iter_Contains(BingoPlayer, playerid)) {
		Player_StopBingo(playerid, false);
		Iter_Remove(BingoPlayer, playerid);
	}
	return 1;
}

CMD:kladionica(playerid, params[]) {
	new bizzid = Player_GetPlayerBizFromInt(playerid);

	if (bizzid == -1) {
		return SendClientMessage(playerid, 0xff6347aa, " * Niste u kladionici.");
	}

	if (FirmaInfo[bizzid][fVrsta] != BUSINESS_TYPE_BETTING_SHOP) {
		return SendClientMessage(playerid, 0xff6347aa, " * Niste u kladionici.");
	}

	if (IsNull(params)) {
		SendClientMessage(playerid, 0xffff00ff, "[SA:RP] {ffffff}/kladionica [Opcija]");
		SendClientMessage(playerid, 0xffff00ff, "Opcije: {ffffff}pomoc, bingo");
		return 1;
	}

	if (!strcmp(params, "pomoc", true)) {
		FDLG_ShowPlayerDialog(
			playerid, 0, DIALOG_STYLE_MSGBOX, "Pomoc",
			"{ffffff}/kladionica bingo (6/48) - otvara dialog u koji se unosi dobitna kombinacija od 6 brojeva (1 - 48)\n\
			\t{ffffff}posle brojeva upisuje se ulog i prebacuje se na TV gdje svi igraci zajedno mogu live da gledaju izvlacenje kombinacije",
			"Izlaz", ""
		);
	}
	else if (!strcmp(params, "bingo", true)) {
		if (Player_IsPlayingBingo(playerid)) {
			return SendClientMessage(playerid, 0xff6347aa, " * Vec ste odigrali bingo listic.");
		}

		FDLG_ShowPlayerDialog(playerid, d_BINGO, DIALOG_STYLE_INPUT, "Sastvaljanje listica", "Upisite vasih 6 srecnih brojeva.\nBrojevi moraju biti od 1 do 48.", "Dalje", "Izlaz");
	}
	else return SendClientMessage(playerid, 0xff6347aa, " * Nepostojeca opcija.");
	return 1;
}

fDialog(7879) {
	if (!response)
		return 1;

	new num1, num2, num3, num4, num5, num6;

	if (sscanf(inputtext, "dddddd", num1, num2, num3, num4, num5, num6))
		return FDLG_ShowPlayerDialog(playerid, d_BINGO, DIALOG_STYLE_INPUT, "Sastvaljanje listica",
			"Upisite vasih 6 srecnih brojeva.\nBrojevi moraju biti od 1 do 48.", "Dalje", "Izlaz"
		);

	if (
		!(1 <= num1 <= 48)
		|| !(1 <= num2 <= 48)
		|| !(1 <= num3 <= 48)
		|| !(1 <= num4 <= 48)
		|| !(1 <= num5 <= 48)
		|| !(1 <= num6 <= 48)
	) {
		return FDLG_ShowPlayerDialog(playerid, d_BINGO, DIALOG_STYLE_INPUT, "Sastvaljanje listica",
			"Upisite vasih 6 srecnih brojeva.\nBrojevi moraju biti od 1 do 48.", "Dalje", "Izlaz"
		);
	}

	g_sBingoNumbers[playerid][0] = num1;
	g_sBingoNumbers[playerid][1] = num2;
	g_sBingoNumbers[playerid][2] = num3;
	g_sBingoNumbers[playerid][3] = num4;
	g_sBingoNumbers[playerid][4] = num5;
	g_sBingoNumbers[playerid][5] = num6;

	new bool:duplicateFound = false;

	for(new i = 0, j; i < 6; i ++) for(j = 0; j < 6; j ++)
		if (i != j && g_sBingoNumbers[playerid][i] == g_sBingoNumbers[playerid][j]) duplicateFound = true;

	if (duplicateFound) {
		return FDLG_ShowPlayerDialog(playerid, d_BINGO, DIALOG_STYLE_INPUT, "Sastvaljanje listica",
			"Upisite vasih 6 srecnih brojeva.\nBrojevi se ne smiju ponavljati.", "Dalje", "Izlaz"
		);
	}

	FDLG_ShowPlayerDialog(playerid, d_BINGO_BET, DIALOG_STYLE_INPUT, "Odredjivanje uloga", "Upisite koliko ulazete u listic (10-10.000$).", "Dalje", "Izlaz");
	return 1;
}

fDialog(7880) {
	if (!response) {
		return 1;
	}

	new value = strval(inputtext);

	if (value < 1 || value > 10000)
		return FDLG_ShowPlayerDialog(playerid, d_BINGO_BET, DIALOG_STYLE_INPUT, "Odredjivanje uloga", "Upisite koliko ulazete u listic (10-10.000$).", "Dalje", "Izlaz");

 	if (value > PlayerInfo[playerid][pNovacDzep])
 		return FDLG_ShowPlayerDialog(playerid, d_BINGO_BET, DIALOG_STYLE_INPUT, "Odredjivanje uloga", "Upisite koliko ulazete u listic (10-10.000$).\n{ff6347} * Nemate toliko novca u dzepu.", "Dalje", "Izlaz");

	if (g_sIsBingoDrawStarted) {
		return SendClientMessage(playerid, 0xff6347aa, " * Sacekajte da se zavrsi izvlacenje.");
	}

	new bizzid = Player_GetPlayerBizFromInt(playerid);

	g_NovacMinus(playerid, value);

	g_sBingoBet[playerid] = value;
	g_sBingoTrueNumbers[playerid] = 0;
	g_sBingoBusinessID[playerid] = bizzid;

	Business_GiveMoney(bizzid, value / 2);

	Player_StartBingo(playerid);
	return 1;
}
