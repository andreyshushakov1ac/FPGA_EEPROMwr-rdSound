/*

ЕСЛИ ХОЧЕШЬ ЗАЛИТЬ ПРОГУ С ЗАПИСЬЮ СДЕЛАЙ RW = 0, ЕСЛИ НА ЧТЕНИЕ, ТО RW = 1 

 SW[17] - разрешение записи с микрофона (1-можно, 0-нельзя) или чтения из eeprom
LED[17] - буфер заполнен звуком с микрофона 
LED[7:0] - сколько посылок по 32 байта данных ЗАПИСАНО в eeprom

LED[15] - Былo ли чтение/запись из/в eeprom (да - горит) 
LED[14] - Есть ли ли чтение/запись из/в eeprom (да - горит) 
LED[13] был ли хоть раз пройден итоговый алвэйс-блок
LED[12] - Всё записано/прочитано в/из еепром и startV0<=1  =>  больше ни одного байта между контроллером и модулем не будет (да - горит)

 KEY[0] - reset
 SW[3:0]- скважность	(разрешение на sound)	
 
 HEX0, HEX1, HEX2 // выодит на 3 семисегмента старшие 4 бита первых трёх 32-битных векторов сформированного readbuff (при RW==1) или databuff (при RW==0)   в 16ричке(!!!)

*/


module DE2_Audio_Example (

///

EEPROM_SDA,
EEPROM_SCL,
///

	// Inputs
	CLOCK_50,
	
	KEY, SW, LED, HEX0, HEX1, HEX2,
	
	
	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	I2C_SCLK
	
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
 
 ///
 output [17:0]LED;
 output reg [6:0] HEX0, HEX1, HEX2;
 
 // буфер заполнен звуком с микрофона
 reg buff_ready;initial buff_ready = 0;
 assign LED[17] = buff_ready; 
 
 // Сколько сообщений по 32 информационных байта записано в eeprom
 reg [7:0] n_32byteMessages; initial n_32byteMessages = 0;
 assign  LED[7:0]= n_32byteMessages; 
 
 
// Есть ли чтение/запись из/в eeprom (да - горит) 
 assign LED[14] = start;
 // Было ли чтение/запись из/в eeprom (да - горит) 
 assign LED[15] = reg_start; 
 reg reg_start; initial reg_start=0;
 always @ (posedge CLOCK_50)
	if (start==1)
		reg_start<=1;
//Всё записано/прочитано в/из еепром и startV0<=1  =>  больше ни одного байта между контроллером и модулем не будет (да - горит)
 assign LED[12] = startV0; 
// был ли хоть раз пройден итоговый алвэйс-блок
assign LED[13] = itogAlwBlock_ok;
reg itogAlwBlock_ok; initial itogAlwBlock_ok = 0;  
 
 inout EEPROM_SDA;
 output EEPROM_SCL;
 
 
 parameter xx = 32'b11111111111111111111111111111111;
 
 ///
 
 
 
 
// Inputs
input				CLOCK_50;
input		[3:0]	KEY; // KEY[0] - reset
input		[17:0]	SW; // sw0-3 скважность		17- разрешение записи с микрофона (1-можно, 0-нельзя)

input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				I2C_SDAT;

// Outputs
output				AUD_XCK;
output				AUD_DACDAT;

output				I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire 				CLOCK_27;
wire				audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
wire				read_audio_in;

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;

// Internal Registers

reg [18:0] delay_cnt, delay;
reg snd;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
	if(delay_cnt == delay) begin
		delay_cnt <= 0;
		snd <= !snd;
	end else delay_cnt <= delay_cnt + 1;

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

assign delay = {SW[3:0], 15'd3000};

wire [31:0] sound = (SW == 0) ? 0 : snd ? 32'd10000000 : -32'd10000000;


assign read_audio_in			= audio_in_available & audio_out_allowed;




// Если читаем с EEPROM, то выводиться в режиме реального времени будет буфер, в который читаем
assign left_channel_audio_out	= (RW==0) ? (left_channel_audio_in/*+sound*/) :  lastBuff ; 
assign right_channel_audio_out = (RW==0) ? (right_channel_audio_in/*+sound*/) : lastBuff ;

assign write_audio_out			= audio_in_available & audio_out_allowed;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/
CLK27 CLK27 (
	.inclk0(CLOCK_50),
	.c0(CLOCK_27)
);
Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50						(CLOCK_50),
	.reset						(~KEY[0]),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),


	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)

);

avconf #(.USE_MIC_INPUT(1)) avc (
	.I2C_SCLK					(I2C_SCLK),
	.I2C_SDAT					(I2C_SDAT),
	.CLOCK_50					(CLOCK_50),
	.reset						(~KEY[0])
);
















////////////////////////////////////////////////////////////////////////////////////////////////////////////


//ЕСЛИ ХОЧЕШЬ ЗАЛИТЬ ПРОГУ С ЗАПИСЬЮ СДЕЛАЙ RW = 1, ЕСЛИ НА ЧТЕНИЕ, ТО RW = 0 (СТРОКА 201)
parameter RW = 1 ; // ЗАПИСЬ 0		ЧТЕНИЕ 1
//=

parameter eeprom_addr7 = 1010000;

reg rw ; initial rw=0; // регистр, для определения бита записи/чтения (НЕ ТРОГАТЬ!!!)
reg [6:0] n_bytes_in; initial n_bytes_in = 34; // кол-во байт, которое хотим передать в одной посылке, включая первые 2 байта адреса

wire start;  // разрешения записи в EEPROM
reg startV0; initial startV0=0; // переводит start в 0 (при 1) при полной записи из буфера
assign start = (buff_ready==1 && startV0==0) ? 1 : 0; //1 - если готов буфер и он ещё не записан


reg [15:0] cell_addr; initial cell_addr = 0;// адрес ячейки для записи
wire eeprByteReceived; // если 1, то state==STATE_ACK
/* Байты данных
 Одна посылка = 32 байта данных (8 32х битных отправлений). Для полного заполнения 
 EEPROM (4000 байт) надо 125 посылок.
Объявляем буфер для left_channel_audio_in
*/ reg [31:0] databuff [0:124][0:7]; 
 

//========


// сохранение входных данных в массив (ЕСЛИ RW = 0)
reg [31:0] prev_left_channel_audio_in; /* initial prev_left_channel_audio_in=left_channel_audio_in; */ // // текущий вектор сохраняем
reg  [7:0] i,m; reg [3:0] j,n; 
initial begin i=0; j=0; m=0; n=0; end

reg hiFromMaster; initial hiFromMaster=0; 
reg hiToMaster; 

//// в принципе это лишнее
/* reg write2_tri_cellAddrSent; // Если ==1, то надо выставить tri_cellAddrSent==1 в другом олвэйс-блоке
initial write2_tri_cellAddrSent=0;  */

///
reg a; initial a=1; // для присвоения prev_left_channel_audio_in=left_channel_audio_in после переключения SW[17]
///

//Выставляем сколько байт хотим отправить в новой посылке. Выставяем проверки-"приветы" между модулями
always @(posedge CLOCK_50) 
begin
//////////////////////
	// если мы не в состоянии STATE_ACK, где единственно происходит проверка счётчика байтов, и этот счётчик == 0
	// => state==STATE_STOP (либо начало) //
	
	
	if (eeprByteReceived==0 && nbytes==0 && RW==0 && rw==0)
		n_bytes_in <= 34; // то готовимся к отправки новой посылки 
		
	else
	
	
	//находимся в начале или стопе
	if (eeprByteReceived==0 && nbytes==0 && RW==1 && rw==0)
	begin
		n_bytes_in <= 2; // указываем только 2 байта для записи адреса
		signalSTARTvmestoSTOP <= 1;
	end
	
	else // после отправки 2 байт: в условии когда tri_cellAddrSent==1 указываем что rx<=1 см ниже
	
	// находимся в STATE_STOP
	if (eeprByteReceived==0 && nbytes==0 && rw==1)
	begin
		n_bytes_in <= 32; // для чтения. При этом уже не нужно отправлять 2 байта адресов ячеек, так что:
		signalSTARTvmestoSTOP <= 0;
		/* write2_tri_cellAddrSent <= 1; */
	end
	
//////////////////////	
	//обратная связь для провреки корректности в автомате 
	if (hiToMaster==1)  // выставляется в трёх состояниях state, ведущих к STATE_ACK
		hiFromMaster <= 1; // ok
	else 
	if (hiToMaster==0) // выставляется в STATE_ACK
		hiFromMaster <= 0; // Если ==0 при проверке в в STATE_ACK, то это ошибка передачи, автомат вернётся STATE_START 
//////////////////////
end


//Заполнение буфера в 4000 байт с микрофона
always @(posedge CLOCK_50) 
begin
	
	///
	
	// присваиваем первые 32 бита 
	if (a==1 && SW[17]==1) // вспом
	begin
		prev_left_channel_audio_in <= left_channel_audio_in;
		a <= 0; // НАДО СИНХРОНИЗИРОВАТЬ ЭТО
	end
	
	///
	
	// если выставлена запись в еепром, разрешение записи микрофона включено и буфер не заполнен
	if (RW==0 && SW[17]==1 && buff_ready==0)
	begin // записываем в буфер голос с микрофона

		if (left_channel_audio_in != prev_left_channel_audio_in && a==0) // если 32 битный вектор с MicIn изменился, а 1ый вектор был успепшно сохранён
		begin
			databuff[i][j] <= left_channel_audio_in; // сохранение входных данных в массив
			
			if (j==7 && i<124) // если одна i-посылка в 32 байта отправлена
			begin
				i <= i + 1;
				j <= 0;
			end
			else
			if (j<7) // если j (32бит=4байт) ещё отправляются в рамках одной i-посылки
				j <= j + 1;
			else 
			if  (i==124 && j==7) //когда буфер заполнен, выставляем флаг в 1
				buff_ready <= 1;//  буфер заполнен => горит LED[17] 

			prev_left_channel_audio_in <= left_channel_audio_in; // cнова сохраняем текущий вектор, чтобы ожидать его изменения
		end			
	end
	
	else
	
	// если чтение 
	if (RW==1)
		buff_ready <= 1; //  
end


//========================================

// для чтения
reg [7:0] byte_readBuff; initial byte_readBuff=0; // байт, куда вычитываться данные будут
reg [31:0] readbuff [0:124][0:7]; // массив, куда будет сохраняться прочитанное
///initial readbuff[0][0][7:0]= (firstByteWasGot==1) ?	byte_readBuff : 0; // присваивание происходит по выходу из STATE_RX, за которым следует STATE_ACK, где будет считаться, что байт из еепром в первые 7бит буфера уже сохраннён  

// для записи
reg [7:0] byte_databuff; // байт для записи в еепром 
initial byte_databuff= (buff_ready==1) ? databuff[0][0][7:0] : 0; // когда массив сформирован, то первый байт для записи сразу равен первому байту массива

wire [7:0] datOrCellAddr; // байт из буфера, либо адрес ячейки 

// адрес ячейки (tri_cellAddrSent) послан?
// 0 (initial) => нет => тогда посылается адрес 1ой ячейки: datOrAddr==cell_addr[7:0]
//1 => послан адрес первой ячейки => тогда посылается адрес 2ой ячейки: datOrAddr==cell_addr[15:8]
//2 => послан адрес второй ячейки => тогда начинают посылаться байты данных: datOrAddr==byte_databuff
reg [1:0] tri_cellAddrSent; initial tri_cellAddrSent = 0; 
assign datOrAddr = (tri_cellAddrSent==2) ? byte_databuff : ( (tri_cellAddrSent==1) ? cell_addr[15:8] : cell_addr[7:0]);

reg nbytes; initial nbytes = 0; //Сколько байт записано/считано от контроллера приходит в режиме реал-тайм

reg wasItAddrByte; initial wasItAddrByte = 0; // если 1 => state попал в STATE_ACK после отправки байта адреса еепром

reg firstByteWasGot; initial firstByteWasGot=0; // если 1 =>  1ый байт уже был прочитан

//////////////////////
 I2C_EEPROM_MasterController I2C_EEPROM_MasterController_inst0
 (
	.hiToMaster(hiToMaster),
	.hiFromMaster(hiFromMaster),
	.signalSTARTvmestoSTOP(signalSTARTvmestoSTOP),
	
	.ack(eeprByteReceived),// если 1, то state==STATE_ACK
	.nbytes(nbytes), // сколько байт осталось записать/считать
	.wasItAddrByte(wasItAddrByte), // если 1 => state попал в STATE_ACK после отправки байта адреса еепром
	.firstByteWasGot(firstByteWasGot), // если 1 =>  1ый байт уже был прочитан
	
	.clk (CLOCK_50),
	.reset(~KEY[0]),
	.start(start), // позволяет атвомату выйти из состояния idle при start==1
	.nbytes_in(n_bytes_in), //отправляем желаемое кол-во байт в посылке:  34 (первые два дареса ячеек для записи) - стандартно; 2 - когда хотим только указать адрес ячейки для считывания
	.addr_in(eeprom_addr7),
	.rw_in(rw), 
	
	.write_data(datOrCellAddr ),
	.read_data(byte_readBuff), // тот же буфер для чтения из eeprom, что и для записи
	
	.sda_w(EEPROM_SDA),
	.scl(EEPROM_SCL)
 );
////////////////////////

// считает биты (а не байты :) ) - чтобы исключить циклы в алвэйс блоках
reg [2:0] byteCount; initial byteCount=1;


///
reg signalSTARTvmestoSTOP ; initial signalSTARTvmestoSTOP  = 0;
///


// 1 байт доставлен 
always @ (posedge eeprByteReceived)
begin
	
if (wasItAddrByte==1 && n_bytes_in==32 && rw==1/*  && write2_tri_cellAddrSent==1 */)
	tri_cellAddrSent <= 2;

	
	
	
if (wasItAddrByte==0) //если контрольный байт уже был получен ранее, а щас пришёл/прочитан какой-то другой
begin	// значит
	//Отправка адресов ячеек
	if (tri_cellAddrSent==0) // если cell_addr[7:0] получен
		tri_cellAddrSent <= 1;
		
	else 
	
	if (tri_cellAddrSent==1) // если cell_addr[15:8] получен
	begin
		tri_cellAddrSent <= 2; 	
		
		///
		//Если мы хотим отправить контрольный байт с указанием, что сейчас будем читать из еепром
		if (RW==1 && rw==0) //проверка, что это будет наш 2ой контрольный байт 
		begin
			rw <= 1; // выставляем бит чтения на адрес eeprom на шине
		end
// далее, т.к. nbytes==2  идем STATE_STOP, а там переставиться (always-блок выше) nbytes==32, а tri_cellAddrSent сделается сразу ==2
		///
	end
	

	else	
	
	if (tri_cellAddrSent==2) // записан/считан 1ый инф. байт (выставлен в initial: byte_databuff==databuff[0][0]][7:0]) 
	begin
	
		// записываем по байтово все 32 бит
		if (byteCount<=3)
		begin
			if (RW==0) // если запись
			begin
				if (byteCount==1)
				begin
					byte_databuff <= databuff[m][n][15:8]; // то записываем обновляем байт для отправки в eeprom из буфера
					byteCount <= byteCount +1;
				end
				
				else
				
				if (byteCount==2)
				begin
					byte_databuff <= databuff[m][n][23:16]; // то записываем байт в eeprom из буфера
					byteCount <= byteCount +1;
				end
				
				else
				
				if (byteCount==3)
				begin
					byte_databuff <= databuff[m][n][31:24]; // то записываем байт в eeprom из буфера
					byteCount <= 5;
				end				
			end
			
			
			
			else 
			
			
			
			if (RW==1) // если чтение
			begin
				if (byteCount==1)
				begin
					readbuff[m][n][7:0] <= byte_readBuff; // сохраняем вычитанный из еепром байт
					byteCount <= byteCount +1;
				end
				
				else
				
				if (byteCount==2)
				begin
					readbuff[m][n][15:8] <= byte_readBuff; // 
					byteCount <= byteCount +1;
				end
				
				else
				
				if (byteCount==3)
				begin
					readbuff[m][n][23:16] <= byte_readBuff; // 
					byteCount <= byteCount +1;
				end
				
				else 
				
				if (byteCount==4)
				begin
					readbuff[m][n][31:24] <= byte_readBuff; //
					byteCount <= 5;
				end
			end
		end
		
		
		else
		begin

			//Начинаем нумерацию индексов буфера при отправки информационных байт + прибавляем к адресам ячеек при отправке одной посылки
			if (n<7 && m<124) // 32 байта (8 раз по 32 бита) ещё не отправлено
			begin	
				n <= n + 1; //следующие 32бита(=4байта) пошли. Так 8 раз
				byteCount<=1;
				
				if (RW==0)
					byte_databuff <= databuff[m][n+1][7:0]; 
			end			
			
			else
			
			if (n==7 && m<124) // 32 байт отправлено/прочитано
			begin
				byteCount<=1;
				m <= m + 1;
				n <= 0;
				
				if (RW==0)
					byte_databuff <= databuff[m+1][0][7:0]; 
				
				if (rw==1) // если читали, то (здесь m==0 всегда, т.к. готовность была прочесть 32 байта)
					rw <= 0; //возвращаем последний бит адреса в 1, т.е. в запись 
				cell_addr <= cell_addr + 32; // адрес ячеек увеличивается
				tri_cellAddrSent <= 0; // адреса 1ой ячейки новой посылки не отправлен
				n_32byteMessages <= n_32byteMessages + 1; // cчётчик записаных/прочитанных сообщений по 32 байта для вывода на первые 8 лампочек
			end
			
			else 
			
			if (m==124 && n<6)
			begin
				n <= n + 1; //следующие 32бита(=4байта) пошли. Так 8 раз
				byteCount<=1;
				
				if (RW==0)
					byte_databuff <= databuff[m][n+1][7:0]; 
			end
			
			else 
			
			if (m==124 && n==6) // если всё записано/прочитано
			begin	
				startV0 <= 1; // запрещаем запись (или чтение из) в EEPROM, переводя start в 0
				
				//обнуляем для будущей передачи в цикл. Главное, что readbuff готов
				m <= 0;
				n <= 0;	
			end
			
		end
	end
	
end // wasItAddrByte==0 ?
end // always




//integer file;
//initial file = $fopen("message.txt", "w");

reg  [7:0] x; reg [3:0] z; 
initial begin x=0; z=0; end
reg [31:0] lastBuff; initial lastBuff = 0;

//reg a0; initial a0 = 0 ;
///reg [1:0] a1; initial a1=0; // для вывода на что-нибудь left_channel_audio_out 
 
always @ (posedge CLOCK_50) ///sound)
begin


	//if (a0==3)
		 //$fclose(file);
		 
		 

	//==
	if (startV0==1 && RW==1)
	begin
		
			lastBuff <= readbuff[x][z];
		
			if (z<7 && x<124) // 32 байта (8 раз по 32 бита) ещё не отправлено	
			begin
				z <= z + 1;		
				//$fdisplay(file, "readbuff[%d][%d] = %d", x, z, readbuff[x][z]); 
			end
			
			else
			
			if (z==7 && x<124) // 32 байт отправлено/прочитано
			begin
				x <= x + 1;
				z <= 0;
				//$fdisplay(file, "readbuff[%d][%d] = %d", x, z, readbuff[x][z]); 
			end
			
			else 
			
			if (x==124 && z<6)
			begin
				z <= z + 1;
				//$fdisplay(file, "readbuff[%d][%d] = %d", x, z, readbuff[x][z]); 
			end
			
			else 
			
			if (x==124 && z==6) // если всё записано/прочитано
			begin	
				x<=0;
				z<=0;
				
				itogAlwBlock_ok <= 1; //для лед13
				
				///a1<=1;
				
				//a0<= a0+1;
				//$fdisplay(file, "readbuff[%d][%d] = %d", x, z, readbuff[x][z]); 
			end
			
		
	end
end 



// выодит на 3 семисегмента старшие 4 бита первых трёх 32-битных векторов сформированного readbuff (при RW==1) или databuff (при RW==0)   в 16ричке(!!!)
wire [3:0] copy0, copy1,copy2; 
deshifr15is2v16 desh1
(
	.binary_in(copy1), 
	.decoder_out(HEX1)
);
deshifr15is2v16 desh2
(
	.binary_in(copy2), 
	.decoder_out(HEX2)
);

deshifr15is2v16 desh0
(
	.binary_in(copy0), 
	.decoder_out(HEX0)
);

assign copy0 = (startV0==1) ? ( (RW==1) ? (readbuff[2][0][31:28]) : (databuff[2][0][31:28]) ) : 0; 
assign copy1 = (startV0==1) ? ( (RW==1) ? (readbuff[3][1][27:23]) : (databuff[3][1][27:23]) ) : 0; 
assign copy2 = (startV0==1) ? ( (RW==1) ? (readbuff[10][2][22:19]) : (databuff[10][2][22:19]) ) : 0; 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* 
Теперь, если читаем из eeprom, будем при считывании каждых 4 байт (32бита на канал), 
сразу выводить их в left_channel_audio_out и right_channel_audio_out	
*/







//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule