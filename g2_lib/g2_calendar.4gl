--------------------------------------------------------------------------------
#+ Genero Genero Library Functions - by Neil J Martin ( neilm@4js.com )
#+
#+ Calendar functions
#+
#+ This library is intended as an example of useful library code for use with
#+ Genero 4.00 and above
#+  
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+  
#+ No includes required.

&ifdef gen320
&else
PACKAGE g2_lib
&endif

IMPORT util

PUBLIC CONSTANT C_MONTHS_IS
		= "Janúar|Febrúar|Mars|Apríl|Maí|Júní|Júlí|Agúst|September|Október|Nóvember|Desember"
PUBLIC CONSTANT C_DAYS3_IS = "Mán|Þri|Mið|Fim|Fös|Lau|Sun"
PUBLIC CONSTANT C_DAYS1_IS = "M|Þ|M|F|F|L|S"
PUBLIC CONSTANT C_MONTHS_ES
		= "Enero|Febrero|Marzo|Abril|Mayo|Junio|Julio|Agosto|Septiembre|Octubre|Noviembre|Diciembre"
PUBLIC CONSTANT C_DAYS3_ES = "Lun|Mar|Mie|Jue|Vie|Sab|Dom"
PUBLIC CONSTANT C_DAYS1_ES = "L|M|M|J|V|S|D"
PUBLIC CONSTANT C_MONTHS_PT
		= "Janeiro|Fevereiro|Março|Abril|Maio|Junho|Julho|Agosto|Setembro|Outubro|Novembro|Dezembro"
PUBLIC CONSTANT C_DAYS3_PT = "Seg|Ter|Qua|Qui|Sex|Sáb|Dom"
PUBLIC CONSTANT C_DAYS1_PT = "S|T|Q|Q|S|S|D"

--------------------------------------------------------------------------------
-- MONTH FUNCTIONS
--------------------------------------------------------------------------------
--
FUNCTION month_fullName_int(m SMALLINT)
	RETURN month_fullName(MDY(m, 1, 2000))
END FUNCTION
--------------------------------------------------------------------------------
--
FUNCTION month_shortName_int(m SMALLINT)
	RETURN month_shortName(MDY(m, 1, 2000))
END FUNCTION
--------------------------------------------------------------------------------
--
FUNCTION month_fullName(dt DATETIME YEAR TO DAY)
--	DISPLAY "DT:",dt," ",util.DateTime.format(dt,"%B")
	RETURN util.Datetime.format(dt, "%B")
END FUNCTION
--------------------------------------------------------------------------------
--
FUNCTION month_shortName(dt DATETIME YEAR TO DAY)
	RETURN util.Datetime.format(dt, "%b")
END FUNCTION

--------------------------------------------------------------------------------
-- DAY FUNCTIONS
--------------------------------------------------------------------------------
--
FUNCTION day_fullName(dt DATETIME YEAR TO DAY)
	RETURN util.Datetime.format(dt, "%A")
END FUNCTION
--------------------------------------------------------------------------------
--
FUNCTION day_shortName(dt DATETIME YEAR TO DAY)
	RETURN util.Datetime.format(dt, "%a")
END FUNCTION
--------------------------------------------------------------------------------
--
FUNCTION isWeekEnd(l_date DATE)
	RETURN WEEKDAY(l_date) = 0 OR WEEKDAY(l_date) = 6
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION days_in_month(x)
	DEFINE x SMALLINT
	CASE x
		WHEN 2
			LET x = 29
		WHEN 4
			LET x = 30
		WHEN 6
			LET x = 30
		WHEN 9
			LET x = 30
		WHEN 11
			LET x = 30
		OTHERWISE
			LET x = 31
	END CASE
	RETURN x
END FUNCTION
