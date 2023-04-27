--------------------------------------------------------------------------------
#+ Genero Genero Library Functions - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 4.00 and above
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.

&ifdef gen320
IMPORT FGL g2_core
IMPORT FGL g2_sql
&else
PACKAGE g2_lib
IMPORT FGL g2_lib.g2_core
IMPORT FGL g2_lib.g2_sql
&endif

PUBLIC TYPE t_init_inp_func FUNCTION(l_new      BOOLEAN, l_d ui.Dialog) RETURNS()
PUBLIC TYPE t_before_inp_func FUNCTION(l_new    BOOLEAN, l_d ui.Dialog) RETURNS()
PUBLIC TYPE t_after_inp_func FUNCTION(l_new     BOOLEAN, l_d ui.Dialog) RETURNS BOOLEAN
PUBLIC TYPE t_after_fld_func FUNCTION(l_fldName STRING, l_fldValue STRING, l_d ui.Dialog) RETURNS()
PUBLIC TYPE t_onChange_func FUNCTION(l_fldName  STRING, l_fldValue STRING, l_d ui.Dialog) RETURNS()
PUBLIC TYPE g2_ui RECORD
	dia             ui.Dialog,
	init_inp_func   t_init_inp_func,
	before_inp_func t_before_inp_func,
	after_inp_func  t_after_inp_func,
	after_fld_func  t_after_fld_func,
	onChange_func   t_onChange_func,
	fields          DYNAMIC ARRAY OF g2_sql.t_fields
END RECORD
--------------------------------------------------------------------------------
FUNCTION (this g2_ui) g2_UIinput(l_new BOOLEAN, l_sql g2_sql.sql, l_acceptAction STRING, l_exitOnAccept BOOLEAN)
	DEFINE x            SMALLINT
	DEFINE l_evt, l_fld STRING

	LET this.fields = l_sql.fields

-- Allow initialize like adding formonly fields or setting noEntry fields.
	IF this.init_inp_func IS NOT NULL THEN
		CALL this.init_inp_func(l_new, this.dia)
	END IF

	IF l_acceptAction.getLength() < 1 THEN
		LET l_acceptAction = "accept"
	END IF

	CALL ui.Dialog.setDefaultUnbuffered(TRUE)

	LET this.dia = ui.Dialog.createInputByName(this.fields)

	IF NOT l_new THEN
		IF l_sql.current_row = 0 THEN
			RETURN
		END IF
	END IF

	FOR x = 1 TO this.fields.getLength()
		IF l_new THEN
			CALL this.dia.setFieldValue(this.fields[x].colName, this.fields[x].defValue)
		ELSE
			CALL this.dia.setFieldValue(this.fields[x].colName, this.fields[x].value)
		END IF
		IF x = l_sql.key_field_num OR this.fields[x].noEntry THEN
			CALL this.dia.setFieldActive(this.fields[x].colName, FALSE)
		END IF
	END FOR

	CALL this.dia.addTrigger("ON ACTION close")
	CALL this.dia.addTrigger("ON ACTION cancel")
	CALL this.dia.addTrigger("ON ACTION clear")
	CALL this.dia.addTrigger("ON ACTION " || l_acceptAction)
	LET int_flag = FALSE
	WHILE TRUE
		LET l_evt = this.dia.nextEvent()
		IF l_evt.subString(1, 11) = "AFTER FIELD" THEN
			LET l_fld = l_evt.subString(13, l_evt.getLength())
			LET l_evt = "AFTER FIELD"
		END IF
		IF l_evt.subString(1, 9) = "ON CHANGE" THEN
			LET l_fld = l_evt.subString(11, l_evt.getLength())
			LET l_evt = "ON CHANGE"
			DISPLAY "ON CHANGE:", l_fld
		END IF
		CASE l_evt
			WHEN "BEFORE INPUT"
				IF this.before_inp_func IS NOT NULL THEN
					CALL this.before_inp_func(l_new, this.dia)
				END IF

			WHEN "AFTER INPUT"
				IF this.after_inp_func IS NOT NULL THEN
					IF NOT this.after_inp_func(l_new, this.dia) THEN
						CONTINUE WHILE
					END IF
				END IF
				IF NOT int_flag THEN
					CALL l_sql.g2_SQLrec2Json()
					IF l_new THEN
						IF l_sql.g2_SQLinsert() THEN
							LET l_new = FALSE -- change to update mode now we have the row inserted
						END IF
					ELSE
						IF NOT l_sql.g2_SQLupdate() THEN
							CONTINUE WHILE
						END IF
					END IF
				END IF
				IF l_exitOnAccept THEN
					EXIT WHILE
				END IF

			WHEN "AFTER FIELD"
				IF this.after_fld_func IS NOT NULL THEN
					CALL this.after_fld_func(l_fld, this.dia.getFieldValue(l_fld), this.dia)
				END IF

			WHEN "ON CHANGE"
				IF this.onChange_func IS NOT NULL THEN
					CALL this.onChange_func(l_fld, this.dia.getFieldValue(l_fld), this.dia)
				END IF
			WHEN "ON ACTION close"
				LET int_flag = TRUE
				EXIT WHILE

			WHEN "ON ACTION clear"
				CALL l_sql.g2_SQLrec2Json()
				FOR x = 1 TO this.fields.getLength()
					CALL this.dia.setFieldValue(this.fields[x].colName, this.fields[x].value)
				END FOR
				CALL l_sql.g2_SQLrec2Json()

			WHEN "ON ACTION " || l_acceptAction
				FOR x = 1 TO this.fields.getLength()
					LET this.fields[x].value = this.dia.getFieldValue(this.fields[x].colName)
				END FOR
				CALL this.dia.accept()

			WHEN "ON ACTION cancel"
				CALL this.dia.cancel()
				EXIT WHILE
		END CASE
	END WHILE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION (this g2_ui) g2_addFormOnlyField(l_name STRING, l_type STRING, l_value STRING, l_noEntry BOOLEAN)
	DEFINE x SMALLINT
	CALL this.fields.appendElement()
	LET x                       = this.fields.getLength()
	LET this.fields[x].colName  = l_name
	LET this.fields[x].colType  = l_type
	LET this.fields[x].value    = l_value
	LET this.fields[x].formOnly = TRUE
	LET this.fields[x].noEntry  = l_noEntry

END FUNCTION
