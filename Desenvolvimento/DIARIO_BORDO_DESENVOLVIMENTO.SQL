---------------------------------------------------------------------
# PROCEDIMENTOS PJE
---------------------------------------------------------------------

    # CONEXOES DE BANCO DE DADOS [DEVE CORRESPONDER AO DBAVER]
        -------------------------------------------------------------------------------------------------------------------------------
        NAME                HOST                    PORT    DATABASE             			USERNANE           PASSWORD           
        -------------------------------------------------------------------------------------------------------------------------------
        ZINCOH01            zincoh02.cnj.jus.br     5432    pje_cnj_prod        			 usuariohoml        pje_cnj_prod      
        -------------------------------------------------------------------------------------------------------------------------------
        ZINCOH02            zincoh02.cnj.jus.br     5432    pje_cnj_prod        			 usuariohoml        hml12#TT                
        -------------------------------------------------------------------------------------------------------------------------------
        ZINCOH02            zincod03.cnj.jus.br     5432    pje_cnj            				  pje2               pje2      
        -------------------------------------------------------------------------------------------------------------------------------  
        ZINCOH02            zincoh02.cnj.jus.br     5432    pje_desenvolvimento_master        usuariohoml        hml12#TT      
        -------------------------------------------------------------------------------------------------------------------------------               
		NAME: 			1-Homologacao(zincoh02.cnj.jus.br - pje_cnj_prod) 
		HOST: 			zincoh02.cnj.jus.br
		USER:            
		PASSWORD:       

		NAME: 			1-Homologacao(zincoh02.cnj.jus.br - pje_desenvolvimento_master)
		NAME:           1-Producao(zinco01.cnj.jus.br - pje_cnj)
		-------------------------------------------------------------------------------------------------------------------------------               

---------------------------------------------------------------------
# PJE CNJ - SCRIPT POSTGRES 
---------------------------------------------------------------------

	## RECUPERAR TABELAS DO BANCO DE DADOS PELO NOME

		SELECT NSPNAME, RELNAME, ATTNAME
		FROM PG_NAMESPACE N, PG_CLASS C, PG_ATTRIBUTE A, PG_TYPE T
		WHERE N.OID = C.RELNAMESPACE
		AND C.RELKIND ILIKE 'R'
		AND A.ATTNUM > 0
		AND NOT A.ATTISDROPPED
		AND A.ATTRELID = C.OID
		AND A.ATTTYPID = T.OID
		AND C.RELNAME ILIKE '%EXPEDIEN%'
		ORDER BY NSPNAME, RELNAME, ATTNAME;

	## RECUPERAR COLUNAS DO BANCO DE DADOS

		SELECT NSPNAME, RELNAME, ATTNAME
		FROM PG_NAMESPACE N, PG_CLASS C, PG_ATTRIBUTE A, PG_TYPE T
		WHERE N.OID = C.RELNAMESPACE
		AND C.RELKIND ILIKE 'R'
		AND A.ATTNUM > 0
		AND NOT A.ATTISDROPPED
		AND A.ATTRELID = C.OID
		AND A.ATTTYPID = T.OID
		AND A.ATTNAME ILIKE '%PRAZO%'
		ORDER BY NSPNAME, RELNAME, ATTNAME;

	## RETORNA UM USUARIO DO SISTEMA PELO PAPEL

		SELECT
			DISTINCT A.ID_USUARIO,
			A.DS_LOGIN,
			A.DS_NOME,
			A.DS_SENHA,
			A.IN_ATIVO,
			A.DT_VALIDADE_SENHA
		FROM
			TB_USUARIO_LOGIN A
		INNER JOIN TB_USUARIO_LOCALIZACAO B ON
			A.ID_USUARIO = B.ID_USUARIO
		WHERE
			B.ID_PAPEL = 1005
			-- ADVOGADO
		ORDER BY
			A.DS_NOME;	

	## ATUALIZAR DADOS DO USUARIO PARA LOGIN

		BEGIN TRANSACTION;
			UPDATE ACL.TB_USUARIO_LOGIN 
			SET DS_SENHA = '$2a$12$Xmr6b9QcSf/6uep1axnV9OV3UUI5yQHlNBRuKB/Et9VpqedzE25Ee', 
			    IN_STATUS_SENHA = 'A', 
			    DT_VALIDADE_SENHA = '2020-01-01'
			WHERE DS_LOGIN IN ('01547345195', '88940764153');
		COMMIT TRANSACTION;
		ROLLBACK TRANSACTION;

	## RESOLVE PROBLEMA DE 'LOCK TABLES'

		TRUNCATE PUBLIC.QRTZ_TRIGGERS CASCADE;
		TRUNCATE PUBLIC.QRTZ_JOB_DETAILS CASCADE;

	## DESCONECTA TODOS OS USUARIOS DE UM BANCO

		SELECT PG_TERMINATE_BACKEND(PID) FROM PG_STAT_ACTIVITY WHERE PID <> PG_BACKEND_PID();

	## ALTERAR 'ORGAO JULGADOR' DE UMA DETERMINADA TAREFA DE UM PROCESSO
	## ALTERAR 'ORGAO JULGADOR' CONFORME O RELATOR DO PROCESSO
	## ALTERAR PROCESSO DE OUTRO RELATOR 

		-- RECUPERAR DADOS DO PROCESSO	
		SELECT
			ID_PROCESSO,
			NR_PROCESSO,
			ID_JBPM,
			ID_FLUXO
		FROM
			TB_PROCESSO
		WHERE
			NR_PROCESSO ILIKE '%0005566-61.2017.2.00.0000%';

		-- VERIFICAR ORGAO JULGADOR DO PROCESSO
		SELECT ORGAO_JULGADOR.DS_ORGAO_JULGADOR
      	FROM TB_PROCESSO_TRF PROCESSO_TRF
            INNER JOIN TB_ORGAO_JULGADOR ORGAO_JULGADOR
                  ON PROCESSO_TRF.ID_ORGAO_JULGADOR = ORGAO_JULGADOR.ID_ORGAO_JULGADOR
            WHERE ID_PROCESSO_TRF = 91436;

        -- RECUPERAR TAREFA ATUAL DE UM DETERMINADO PROCESSO  
		SELECT TASK.NAME_, TASK.PROCINST_ FROM JBPM_TASKINSTANCE TASK
		INNER JOIN JBPM_VARIABLEINSTANCE VAR ON VAR.PROCESSINSTANCE_ = TASK.PROCINST_
		WHERE VAR.LONGVALUE_ IN (SELECT ID_PROCESSO FROM CORE.TB_PROCESSO WHERE NR_PROCESSO ILIKE '%0005566-61.2017.2.00.0000%')
		AND TASK.END_ IS NULL;

		-- RECUPERA A ORDEM DE DOS ID'S DOS 'ORGAO JULGADOR' ATUAL DO PROCESSO
		-- RECUPERA O ORGAO JULGADOR ATUAL DO PROCESSO PELA 'PROCINSTANCE_'
		SELECT * FROM TB_PROCESSO_INSTANCE WHERE ID_PROCESSO = 91436 AND ID_PROC_INST = 16147342;

		-- RECUPERA 'ORGAO JULGADOR' DE DESTINO
		SELECT ID_ORGAO_JULGADOR, DS_ORGAO_JULGADOR FROM CLIENT.TB_ORGAO_JULGADOR WHERE ID_ORGAO_JULGADOR = 7;

		-- RETORNA OS DADOS DO ORGAO JULGADOR DE DESTINO
		SELECT ID_ORGAO_JULGADOR, 
		       ID_ORGAO_JULGADOR_CARGO, 
		       ID_ORGAO_JULGADOR_COLEGIADO 
		      FROM CORE.TB_PROCESSO_INSTANCE 
		      WHERE ID_ORGAO_JULGADOR =  7 
		      LIMIT 1;

		-- ATUALIZAR OS DADOS PARA O ORGAO JULGADOR CORRETO
		-- ID_PROCESSO      =  91436
		-- ID_PROCINSTANCE_ =  16147342
		BEGIN;
		      --UPDATE CORE.TB_PROCESSO_INSTANCE
		      SET   ID_ORGAO_JULGADOR = 7,
		            ID_ORGAO_JULGADOR_CARGO = 12,
		            ID_ORGAO_JULGADOR_COLEGIADO = 2
		      WHERE ID_PROCESSO = 91436
		            AND ID_PROC_INST = 16147342;
		COMMIT TRANSACTION;
		-- ROLLBACK TRANSACTION;

	## REMOVER ASSINATURA DE DOCUMENTO DE RELATORIO

		-- VERIFICAR SE O PROCESSO QUE FOI ABERTO O CHAMADO ESTA NESSA CONDICAO
			SELECT var.id_ , A.nr_processo
			FROM jbpm_taskinstance task
			INNER JOIN jbpm_variableinstance var 
			ON var.processinstance_ = task.procinst_
			INNER JOIN core.tb_processo_documento doc1 
			ON doc1.id_processo_documento = var.longvalue_
			INNER JOIN core.tb_processo proc 
			ON proc.id_processo = doc1.id_processo
			INNER JOIN client.tb_processo_trf trf 
			ON trf.id_processo_trf = doc1.id_processo
			INNER JOIN TB_PROCESSO A 
			ON A.id_processo = doc1.id_processo
			AND ( var.name_ = 'minutaEmElaboracao' )
			AND ( var.longvalue_ IS NOT NULL )
			AND EXISTS ( SELECT 1
			FROM core.tb_processo_documento doc
			INNER JOIN client.tb_proc_doc_bin_pess_assin assin 
			ON assin.id_processo_documento_bin = doc.id_processo_documento_bin
			WHERE doc.id_processo_documento = var.longvalue_
			AND doc.dt_juntada IS NOT NULL
			AND assin.dt_assinatura IS NOT NULL
			AND assin.ds_assinatura IS NOT NULL
			AND assin.ds_cert_chain IS NOT NULL )
			AND task.end_ IS NULL
			AND A.nr_processo ILIKE '%%'
			ORDER BY dt_juntada DESC;

		-- CORRECAO PALIATIVA DO PROBLEMA	
			BEGIN TRANSACTION;
				--UPDATE JBPM_VARIABLEINSTANCE
				     SET LONGVALUE_ = NULL 
				WHERE ID_ 
					IN (SELECT VAR.ID_
						FROM JBPM_TASKINSTANCE TASK
						INNER JOIN JBPM_VARIABLEINSTANCE VAR ON VAR.PROCESSINSTANCE_ = TASK.PROCINST_
						INNER JOIN CORE.TB_PROCESSO_DOCUMENTO DOC1 ON DOC1.ID_PROCESSO_DOCUMENTO = VAR.LONGVALUE_
						INNER JOIN CORE.TB_PROCESSO PROC ON PROC.ID_PROCESSO = DOC1.ID_PROCESSO
						INNER JOIN CLIENT.TB_PROCESSO_TRF TRF ON TRF.ID_PROCESSO_TRF = DOC1.ID_PROCESSO
						AND (VAR.NAME_ = 'minutaEmElaboracao')
						AND (VAR.LONGVALUE_ IS NOT NULL)
						AND EXISTS 
							(SELECT 1 FROM CORE.TB_PROCESSO_DOCUMENTO DOC
								INNER JOIN CLIENT.TB_PROC_DOC_BIN_PESS_ASSIN ASSIN ON ASSIN.ID_PROCESSO_DOCUMENTO_BIN = DOC.ID_PROCESSO_DOCUMENTO_BIN
								WHERE DOC.ID_PROCESSO_DOCUMENTO = VAR.LONGVALUE_
									AND DOC.DT_JUNTADA IS NOT NULL
									AND ASSIN.DT_ASSINATURA IS NOT NULL
									AND ASSIN.DS_ASSINATURA IS NOT NULL
									AND ASSIN.DS_CERT_CHAIN IS NOT NULL)
					      AND TASK.END_ IS NULL
					      ORDER BY DT_JUNTADA DESC
					      );
			COMMIT TRANSACTION;

	## TRANSLADAR TODOS OS DOCUMENTOS DE UM PROCESSO PARA OUTRO

		BEGIN TRANSACTION;
		  INSERT INTO CORE.TB_PROCESSO_DOCUMENTO 
		    SELECT NEXTVAL('CORE.SQ_TB_PROCESSO_DOCUMENTO'),
		           DS_PROCESSO_DOCUMENTO,
		           (SELECT ID_PROCESSO FROM CORE.TB_PROCESSO WHERE	NR_PROCESSO ILIKE '%0002416-38.2018.2.00.0000%'),
		           ID_USUARIO_INCLUSAO,
		           ID_USUARIO_EXCLUSAO,
		           DT_INCLUSAO,
				   DT_EXCLUSAO,
		     	   DS_MOTIVO_EXCLUSAO,
		           IN_ATIVO,
		           ID_TIPO_PROCESSO_DOCUMENTO,
		           ID_PROCESSO_DOCUMENTO_BIN,
		           DS_OBSERVACAO_PROCEDIMENTO,
		           ID_JBPM_TASK,
		           IN_DOCUMENTO_SIGILOSO,
		           ID_PAPEL,
		           ID_USUARIO_ALTERACAO,
		           ID_LOCALIZACAO,
		           DS_NOME_USUARIO_INCLUSAO,
		           DS_NOME_PAPEL,
		           DS_NOME_USUARIO_ALTERACAO,
		           DS_NOME_USUARIO_EXCLUSAO, 
		           DS_NOME_LOCALIZACAO, DT_ALTERACAO, 
		           ID_PK_TB_PROCESSO_DOCUMENTO_PG,
		           ID_SESSAO_PG,
		           ID_DOCUMENTO_PRINCIPAL,
		           NR_DOCUMENTO,
		           DS_INSTANCIA,
		           DT_JUNTADA,
		           IN_LIDO,
		           NR_ORDEM,
		           ID_INSTANCIA_ORIGEM	
		    	FROM CORE.TB_PROCESSO_DOCUMENTO 
		   		WHERE ID_PROCESSO = (SELECT ID_PROCESSO FROM CORE.TB_PROCESSO WHERE	NR_PROCESSO ILIKE '%0003035-75.2012.2.00.0000%'); 
		END; 
		COMMIT TRANSACTION;
		ROLLBACK TRANSACTION;	

	## DOCUMENTO NAO APARECE NA SESSAO

		BEGIN ;
			UPDATE CLIENT.TB_SESSAO_PROC_DOCUMENTO
				SET ID_SESSAO = 474
					WHERE ID_PROCESSO_DOCUMENTO IN(2170569);
		END ;
		COMMIT;
		ROLLBACK;	

	## DOCUMENTOS NAO PARECEM NA CONSULTA PUBLICA

		BEGIN ;
			UPDATE CLIENT.TB_PROCESSO_EXPEDIENTE
				SET IN_DOCUMENTO_EXISTENTE = FALSE
					WHERE ID_PROCESSO_EXPEDIENTE IN (SELECT ID_PROCESSO_EXPEDIENTE FROM TB_PROCESSO_EXPEDIENTE WHERE ID_PROCESSO_DOCUMENTO = 2034767);
			END; 
		COMMIT;	

	## ALTERAR DATA DE UMA DETERMINADA SESSAO

		BEGIN;
			UPDATE CLIENT.TB_SESSAO
				SET DT_SESSAO = '2018-04-24'
				WHERE ID_SESSAO = 474;
		COMMIT;

	## SCRITP PARA INICIAR SESSAO [IMPLEMENTAR] 

		UPDATE TB_SESSAO
		 SET IN_INICIAR = 't',
		     DT_ABERTURA_SESSAO = NOW()		     
		     WHERE ID_SESSAP = xpto; 

	## REMOVER ASSINATURA DE DOCUMENTO DE RELATORIO

		BEGIN ;
			--UPDATE JBPM_VARIABLEINSTANCE
			     SET LONGVALUE_ = NULL 
			WHERE ID_ 
				IN (SELECT VAR.ID_
					FROM JBPM_TASKINSTANCE TASK
					INNER JOIN JBPM_VARIABLEINSTANCE VAR ON VAR.PROCESSINSTANCE_ = TASK.PROCINST_
					INNER JOIN CORE.TB_PROCESSO_DOCUMENTO DOC1 ON DOC1.ID_PROCESSO_DOCUMENTO = VAR.LONGVALUE_
					INNER JOIN CORE.TB_PROCESSO PROC ON PROC.ID_PROCESSO = DOC1.ID_PROCESSO
					INNER JOIN CLIENT.TB_PROCESSO_TRF TRF ON TRF.ID_PROCESSO_TRF = DOC1.ID_PROCESSO
					AND (VAR.NAME_ = 'minutaEmElaboracao')
					AND (VAR.LONGVALUE_ IS NOT NULL)
					AND EXISTS 
						(SELECT 1 FROM CORE.TB_PROCESSO_DOCUMENTO DOC
							INNER JOIN CLIENT.TB_PROC_DOC_BIN_PESS_ASSIN ASSIN ON ASSIN.ID_PROCESSO_DOCUMENTO_BIN = DOC.ID_PROCESSO_DOCUMENTO_BIN
							WHERE DOC.ID_PROCESSO_DOCUMENTO = VAR.LONGVALUE_
								AND DOC.DT_JUNTADA IS NOT NULL
								AND ASSIN.DT_ASSINATURA IS NOT NULL
								AND ASSIN.DS_ASSINATURA IS NOT NULL
								AND ASSIN.DS_CERT_CHAIN IS NOT NULL)
				      AND TASK.END_ IS NULL
				      ORDER BY DT_JUNTADA DESC
				      );
		COMMIT TRANSACTION;

	## RETORNA QUANTIDADE DE PROCESSOS COM A ETIQUETA 'PGTO_MAGISTRADOS'

		SELECT
			PROCESSO.ID_PROCESSO,  
			PROCESSO.NR_PROCESSO,
			PROCESSO_TAREFA.NM_TAREFA
		FROM
			TB_PROCESSO PROCESSO
		INNER JOIN TB_PROCESSO_TRF PROCESSO_TRF 
			ON PROCESSO.ID_PROCESSO = PROCESSO_TRF.ID_PROCESSO_TRF	
		INNER JOIN TB_PROCESSO_TAREFA PROCESSO_TAREFA 
			ON PROCESSO_TAREFA.ID_PROCESSO_TRF = PROCESSO_TRF.ID_PROCESSO_TRF	
		WHERE
			EXISTS(
				SELECT *
				FROM
					CLIENT.TB_PROCESSO_TAG PROCESSO_TAG
				INNER JOIN TB_TAG TAG ON
					PROCESSO_TAG.ID_TAG = TAG.ID
				WHERE
					PROCESSO_TAG.ID_PROCESSO = PROCESSO_TRF.ID_PROCESSO_TRF
					AND TAG.DS_TAG IN('PGTO_MAGISTRADOS'))
				GROUP BY PROCESSO.ID_PROCESSO, PROCESSO.NR_PROCESSO, PROCESSO_TAREFA.NM_TAREFA
					ORDER BY PROCESSO.NR_PROCESSO;	

	## DOCUMENTO NAO APARECE NA SESSAO

	BEGIN ;
		UPDATE CLIENT.TB_SESSAO_PROC_DOCUMENTO
			SET ID_SESSAO = 474
				WHERE ID_PROCESSO_DOCUMENTO IN(2170569);
	END ;
	COMMIT;
	ROLLBACK;

	## DOCUMENTOS NAO PARECEM NA CONSULTA PUBLICA

		BEGIN ;
			UPDATE CLIENT.TB_PROCESSO_EXPEDIENTE
				SET IN_DOCUMENTO_EXISTENTE = FALSE
					WHERE ID_PROCESSO_EXPEDIENTE IN (SELECT ID_PROCESSO_EXPEDIENTE FROM TB_PROCESSO_EXPEDIENTE WHERE ID_PROCESSO_DOCUMENTO = 2034767);
			END; 
		COMMIT;

	## ALTERAR DATA DE UMA DETERMINADA SESSAO

		BEGIN;
			UPDATE CLIENT.TB_SESSAO
				SET DT_SESSAO = '2018-04-24'
				WHERE ID_SESSAO = 474;
		COMMIT;

	## VERIFICAR PROCESSOS COM PRAZOS GERADOS A PARTIR DE UMA SESSAO
	
		SELECT EXP.ID_PROCESSO_EXPEDIENTE 
		FROM CLIENT.TB_PROCESSO_EXPEDIENTE EXP
	        INNER JOIN CLIENT.TB_PROC_PARTE_EXPEDIENTE AS PARTEXP 
	                ON PARTEXP.ID_PROCESSO_EXPEDIENTE = EXP.ID_PROCESSO_EXPEDIENTE
	        INNER JOIN CLIENT.TB_SESSAO_PAUTA_PROC_TRF AS PAUTA
	                ON PAUTA.ID_PROCESSO_TRF = EXP.ID_PROCESSO_TRF
	        WHERE PARTEXP.QT_PRAZO_LEGAL_PARTE = 5
	        AND (TO_CHAR(EXP.DT_CRIACAO_EXPEDIENTE, 'YYYY-MM-DD') = '2018-05-10')
	        AND (TO_CHAR(PARTEXP.DT_CIENCIA_PARTE, 'YYYY-MM-DD') >= '2018-05-10' 
	                OR PARTEXP.DT_CIENCIA_PARTE IS NULL)
	        AND PAUTA.ID_SESSAO = 482
	        AND EXP.ID_TIPO_PROCESSO_DOCUMENTO = 71
	        ORDER BY PAUTA.ID_PROCESSO_TRF DESC;	


	## LIBERAR VOTO, RELATORIO E EMENTA

		-- RECUPERAR TIPOS DE DOCUMENTOS
		SELECT * FROM CORE.TB_TIPO_PROCESSO_DOCUMENTO WHERE ID_TIPO_PROCESSO_DOCUMENTO IN(72,73,77); -- RELATORIO, VOTO E EMENTA

		-- RECUPERAR VOTO, EMENTA E RELATORIO DE UM PROCESSO
		SELECT * 
			FROM CLIENT.TB_SESSAO_PROC_DOCUMENTO AS SPD
			INNER JOIN CORE.TB_PROCESSO_DOCUMENTO AS PD ON PD.ID_PROCESSO_DOCUMENTO = SPD.ID_PROCESSO_DOCUMENTO
			WHERE ID_PROCESSO = (SELECT ID_PROCESSO FROM CORE.TB_PROCESSO WHERE NR_PROCESSO ILIKE '%7055-70%') -- NUMERO DO PROCESSO
			AND ID_TIPO_PROCESSO_DOCUMENTO IN (72,73,77);
			
		-- RECUPERAR DADOS DOS DOCUMENTOS DA SESSAO	
		SELECT * FROM TB_SESSAO_PROC_DOCUMENTO WHERE ID_SESSAO_PROCESSO_DOCUMENTO IN(31978,31979,31980);

		-- ALTERAR A SESSAO 
		BEGIN;
			UPDATE CLIENT.TB_SESSAO_PROC_DOCUMENTO
				SET IN_LIBERACAO = TRUE, 
				    ID_SESSAO = NULL
			WHERE ID_SESSAO_PROCESSO_DOCUMENTO IN(31978,31979,31980) 
			  AND ID_PROCESSO_DOCUMENTO IN(2311188,2311194,2311250);
		COMMIT;	

	## ABRIR TAREFA PARA UM DETERMINADO PROCESSO

		BEGIN;

			--select * from tb_processo where nr_processo ilike '%0000077-09.2018.2.00.0000%';

			--Processo numero : 0000077-09.2018.2.00.0000   --<<<<<<<<<<<<<<<<<<<<<<<<<<CTRL + F e substituir todos os numeros do processo
			--voltar para a tarefa: Cumprir determinações

			--SELECT DE TODAS AS TAREFAS DO PROCESSO
			/*
			SELECT *
			FROM JBPM_TASKINSTANCE TASK
			INNER JOIN JBPM_VARIABLEINSTANCE VAR ON
			TASK.PROCINST_ = VAR.PROCESSINSTANCE_
			AND VAR.CLASS_ ILIKE 'L'
			AND VAR.NAME_ ILIKE 'PROCESSO'
			AND VAR.LONGVALUE_ = ( SELECT ID_PROCESSO FROM CORE.TB_PROCESSO WHERE NR_PROCESSO LIKE '%0004897-71.2018.2.00.0000%')
			ORDER BY TASK.ID_ DESC;
			*/

			--FECHAR A TASKINSTANCE ATUALMENTE ABERTA - OLD
			--SELECT DA TAREFA ABERTA DO PROCESSO
			/*
			select * from jbpm_taskinstance task
			inner join jbpm_variableinstance var
			                on task.procinst_ = var.processinstance_
			                and var.class_  = 'L'
			                and var.name_ = 'processo'
			                and var.longvalue_ = (select id_processo from core.tb_processo where nr_processo like '%0000077-09.2018.2.00.0000%')
			and end_ is null
			order by task.id_;
			*/
			--update jbpm_taskinstance set start_ = now(), end_ = now(), isopen_ = false, issignalling_ = false where id_ = 18475706;-- <<<<<<<<<<<<<<<<<<<<CTRL + f - INSERIR A ID DA TASKINSTANCE

			--PROCESSO ESTÁ SEM NO

			--REABRIR O NÓ DESEJADO
			--SELECT DA TAREFA QUE SE QUER REABRIR
			/*
			select *
			from jbpm_taskinstance task
			inner join jbpm_variableinstance var
			                on task.procinst_ = var.processinstance_
			                and var.class_  = 'L'
			                and var.name_ = 'processo'
			                and var.longvalue_ = (select id_processo from core.tb_processo where nr_processo like '%0000077-09.2018.2.00.0000%')
			and task.name_ ilike 'Avaliar conclusão do julgamento'
			order by task.id_ desc limit 1;

			*/
			UPDATE jbpm_taskinstance 
			                SET end_ = null, isopen_ = true, issignalling_ = true 
			WHERE id_ = 18475706;


			--DAR NOVO SELECT NA TASKINSTANCE QUE SE QUER ABRIR E ANOTAR OS SEGUINTES DADOS:
			--SELECT DA TAREFA QUE SE QUER REABRIR PARA DADOS
			/*
			select task_, task.token_, procinst_, longvalue_
			from jbpm_taskinstance task
			inner join jbpm_variableinstance var
			                on task.procinst_ = var.processinstance_
			                and var.class_  = 'L'
			                and var.name_ = 'processo'
			                and var.longvalue_ = (select id_processo from core.tb_processo where nr_processo like '%0000077-09.2018.2.00.0000%')
			and task.name_ ilike 'Avaliar conclusão do julgamento'
			order by task.id_ desc limit 1;
			*/
			--TASK - 17668088 --<<<<<<<<<<<<<<<<<<<<<<<<<<<<CTRL + f - substituir todos
			--TOKEN - 17355607 --<<<<<<<<<<<<<<<<<<<<<<<<<<<<CTRL + f - substituir todos
			--PROCESSINSTANCE - 17355606 --<<<<<<<<<<<<<<<<<<<<<<<<<<<<CTRL + f - substituir todos
			--ID PROCESSO - 98518 --<<<<<<<<<<<<<<<<<<<<<<<<<<<<CTRL + f - substituir todos

			--TASK

			--select tasknode_ from jbpm_task where id_ = 17668088;

			--task node_ = 17668080 --<<<<<<<<<<<<<<<<<<<<<<<<<<<<CTRL + f - substituir todos

			--ATUALIZAR O TOKEN

			--select * from jbpm_token where id_ in (17355607);

			UPDATE jbpm_token 
			                SET end_ = null, isabletoreactivateparent_ = true, node_ = 17668080, processinstance_ = 17355606 
			WHERE id_ = 17355607;

			-- tb_processo_instance

			--select * from core.tb_processo_instance where id_processo = 98518 and id_proc_inst = 17355606;

			UPDATE  core.tb_processo_instance 
			   SET in_ativo = true 
			WHERE id_processo = 98518 AND id_proc_inst = 17355606;

			INSERT INTO core.tb_proc_localizacao_ibpm 
			                VALUES ((select nextval('core.sq_tb_proc_localizacao_ibpm')), 17668088, 17355606, 98518, 9, 1338);

		COMMIT;

	## UNIFICAR USUARIO DUPLICADO NO PJE

	 -- SCRIPT RESPONSÁVEL POR VERIFICAR SE EXISTE UM USUÁRIO DUPLICADO NA BASE DO CNJ/PJE
		DROP TABLE IF EXISTS DADOS_PESSOA_TEMP;
		CREATE TEMP TABLE DADOS_PESSOA_TEMP AS 
		                (
		                               SELECT CAST('%VITAGLIANO%' AS VARCHAR(255)) as nome_pessoa,
		                               CAST('jakjaljaljaoj' AS varchar(250)) as cpf_pessoa,
		                                CAST('wrfgshtrbfbsrtbh' AS varchar(250)) as oab_pessoa,
		                               CAST('wwwwwww@eee.com' AS varchar(250)) as email_pessoa,
		                               CAST('00000000' AS bigint) as id_pessoa
		                )
		;
		SELECT * FROM DADOS_PESSOA_TEMP;

		select
		CASE 
		WHEN ((((pf.id_pessoa_fisica IS NOT NULL) OR (jr.id_pessoa_juridica IS NOT NULL)) 
		AND ul.id_papel = '5788') 
		AND (((Select COUNT (id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where id_pessoa = l.id_usuario) >= 1 
		AND (di.cd_tp_documento_identificacao = 'RG' OR di.cd_tp_documento_identificacao = 'TIT' OR di.cd_tp_documento_identificacao = 'CPF')) 
		AND pf.id_municipio_nascimento IS NOT NULL 
		AND pf.in_sexo IS NOT NULL
		AND pf.nm_genitora IS NOT NULL
		AND (((Select COUNT (id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where cd_tp_documento_identificacao = 'CPF' AND id_pessoa = pf.id_pessoa_fisica ) >= 1))
		AND (((Select COUNT (id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where cd_tp_documento_identificacao = 'RG' AND id_pessoa = pf.id_pessoa_fisica) >= 1))
		AND (((Select COUNT (id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where cd_tp_documento_identificacao = 'TIT' AND id_pessoa = pf.id_pessoa_fisica) >= 1))
		AND pf.dt_nascimento IS NOT NULL
		AND l.ds_email IS NOT NULL
		AND (SELECT COUNT (nm_logradouro) from core.tb_endereco where id_usuario = l.id_usuario) > 0))--JUS POSTULANDI
		OR
		((pf.id_pessoa_fisica IS NOT NULL AND ad.id IS NOT NULL)
		AND ul.id_papel = '1005'
		AND (((Select COUNT (id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where id_pessoa = l.id_usuario) >= 2)
		AND pf.dt_nascimento IS NOT NULL
		AND pf.nm_genitora IS NOT NULL
		AND pf.in_sexo IS NOT NULL
		AND (ad.id_uf_oab IS NOT NULL AND ad.in_tipo_inscricao IS NOT NULL)
		AND (SELECT COUNT (nm_logradouro) from core.tb_endereco where id_usuario = l.id_usuario) > 0)
		AND l.ds_email IS NOT NULL
		AND (pf.nr_ddd_celular IS NOT NULL AND length(pf.nr_ddd_celular) > 1 AND pf.nr_celular IS NOT NULL AND length(pf.nr_celular) >=8))--ADVOGADO
		--OR
		--MAGISTRADO
		OR
		((pf.id_pessoa_fisica IS NOT NULL AND pr.id IS NOT NULL)
		AND l.ds_email IS NOT NULL
		AND l.ds_login IS NOT NULL
		AND (((Select COUNT (id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where cd_tp_documento_identificacao = 'CPF' AND id_pessoa = pf.id_pessoa_fisica) >= 1))
		AND pf.in_sexo IS NOT NULL
		AND pf.dt_nascimento IS NOT NULL
		AND pf.nm_genitora IS NOT NULL
		AND pf.dt_nascimento IS NOT NULL
		AND pr.id_procuradoria IS NOT NULL
		)--PROCURADOR
		OR
		((pf.id_pessoa_fisica IS NOT NULL AND serv.id IS NOT NULL)
		AND (((Select COUNT (id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where cd_tp_documento_identificacao = 'CPF' AND id_pessoa = pf.id_pessoa_fisica) >= 1))
		AND l.ds_email IS NOT NULL
		AND l.ds_login IS NOT NULL
		AND pf.in_sexo IS NOT NULL
		AND pf.dt_nascimento IS NOT NULL
		AND pf.nm_genitora IS NOT NULL
		AND pf.id_municipio_nascimento IS NOT NULL
		)--SERVIDOR

		OR
		((jr.id_pessoa_juridica IS NOT NULL)
		AND (((Select COUNT (id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where cd_tp_documento_identificacao = 'CPJ' AND id_pessoa = jr.id_pessoa_juridica ) >= 1)
		AND l.ds_login IS NOT NULL
		AND l.ds_email IS NOT NULL
		AND ((select count(id_pessoa) from client.tb_pessoa where id_pessoa = l.id_usuario) > 0 )
		AND ((select count(id_usuario_localizacao) from core.tb_usuario_localizacao where id_usuario = l.id_usuario) > 0 )
		))--PESSOA JURIDICA

		THEN 'OK'
		ELSE 'ERRO' END RESUMO,

		l.id_usuario,


		CASE WHEN pf.id_pessoa_fisica IS NOT NULL 
		AND (ad.id IS NULL 
		AND (ul.id_papel IS NULL OR ul.id_papel <> '5788') 
		AND assisAdv.id IS NULL 
		AND mag.id IS NULL 
		AND serv.id IS NULL 
		AND pr.id IS NULL 
		AND assisAdv.id IS NULL 
		AND pessAutor.id_pessoa_autoridade IS NULL 
		AND ofjus.id IS NULL 
		AND jr.id_pessoa_juridica IS NULL 
		AND psh.id_pessoa_push IS NULL) 
		THEN 'SO PESS FISICA' 
		ELSE '' END so_pf,
		CASE WHEN pf.id_pessoa_fisica IS NOT NULL 
		THEN 'SIM' 
		ELSE '' END pess_fis,
		CASE WHEN pf.id_pessoa_fisica IS NOT NULL AND ad.id IS NOT NULL THEN 'SIM' ELSE '' END adv,
		CASE WHEN ((pf.id_pessoa_fisica IS NOT NULL) OR (jr.id_pessoa_juridica IS NOT NULL)) AND ul.id_papel = '5788' THEN 'SIM' ELSE '' END jusP,
		CASE WHEN pf.id_pessoa_fisica IS NOT NULL AND assisAdv.id IS NOT NULL THEN 'SIM' ELSE '' END assitAdv,
		CASE WHEN pf.id_pessoa_fisica IS NOT NULL AND mag.id IS NOT NULL THEN 'SIM' ELSE '' END magis,
		CASE WHEN pf.id_pessoa_fisica IS NOT NULL AND serv.id IS NOT NULL THEN 'SIM' ELSE '' END serv,
		CASE WHEN pf.id_pessoa_fisica IS NOT NULL AND pr.id IS NOT NULL THEN 'SIM' ELSE '' END proc,
		CASE WHEN l.id_usuario IS NOT NULL AND pessAutor.id_pessoa_autoridade IS NOT NULL THEN 'SIM' ELSE '' END autor,
		CASE WHEN l.id_usuario IS NOT NULL AND ofjus.id IS NOT NULL THEN 'SIM' ELSE '' END ofJus,
		CASE WHEN jr.id_pessoa_juridica IS NOT NULL THEN 'SIM' ELSE '' END PJ,
		CASE WHEN psh.id_pessoa_push IS NOT NULL THEN 'SIM' ELSE '' END push,

		--USUARIO
		CASE WHEN l.id_usuario IS NOT NULL AND l.ds_email IS NOT NULL THEN '' ELSE 'erro' END email,
		CASE WHEN l.id_usuario IS NOT NULL AND l.ds_login IS NOT NULL AND (length(l.ds_login) = 11 OR length(l.ds_login) = 14) THEN '' ELSE 'erro' END login,

		--PESSOA
		--CASE WHEN pes.id_tipo_pessoa IS NOT NULL THEN pes.id_tipo_pessoa ELSE '' END tipo_pessoa,
		--CASE WHEN pes.in_tipo_pessoa IS NOT NULL THEN pes.in_tipo_pessoa ELSE 'erro' END in_tipo_pessoa,
		CASE WHEN ((pes.id_tipo_pessoa = 2 AND pes.in_tipo_pessoa = 'J') OR (pes.id_tipo_pessoa = 3 AND pes.in_tipo_pessoa = 'F')) AND l.ds_cert_chain_usuario IS NOT NULL THEN 'OK' ELSE 'erro' END COMUNICACAO_SISTEMA,

		--LOCALIZACAO
		CASE WHEN ((pl.id_pessoa_localizacao IS NULL AND jr.id_pessoa_juridica IS NOT NULL) 
		OR (pl.id_pessoa_localizacao IS NOT NULL AND jr.id_pessoa_juridica IS NULL)) THEN '' ELSE 'SEM LOCALIZACAO' END pes_localizacao,
		CASE WHEN ul.id_usuario_localizacao IS NOT NULL THEN '' ELSE 'SEM LOCALIZACAO' END usu_localizacao,
		CASE WHEN loc.id_localizacao IS NOT NULL THEN loc.ds_localizacao ELSE 'ERRO' END localizacao,

		--DOCUMENTO IDENTIFICACAO
		CASE WHEN ((select count(id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where id_pessoa = l.id_usuario) > 0 )
		THEN ''
		ELSE 'SEM DOCUMENTOS' END tem_doc,
		CASE WHEN (jr.id_pessoa_juridica IS NOT NULL)--pessoa juridica nao tem CPF
		OR ((select count(id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where id_pessoa = l.id_usuario AND cd_tp_documento_identificacao = 'CPF') > 0 )
		THEN ''
		ELSE 'erro' END CPF,
		CASE WHEN (jr.id_pessoa_juridica IS NOT NULL)--pessoa juridica nao tem TIT
		OR ((select count(id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where id_pessoa = l.id_usuario AND cd_tp_documento_identificacao = 'TIT') > 0 )
		THEN ''
		ELSE 'erro' END TIT,
		CASE WHEN (jr.id_pessoa_juridica IS NOT NULL)--pessoa juridica nao tem RG
		OR ((select count(id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where id_pessoa = l.id_usuario AND cd_tp_documento_identificacao = 'RG') > 0 )
		THEN ''
		ELSE 'erro' END RG,
		CASE WHEN (jr.id_pessoa_juridica IS NOT NULL)--pessoa juridica nao tem OAB
		OR  
		((select count(id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where id_pessoa = l.id_usuario AND cd_tp_documento_identificacao = 'OAB') > 0 ) AND ad.id IS NOT NULL
		OR
		((select count(id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where id_pessoa = l.id_usuario AND cd_tp_documento_identificacao = 'OAB') = 0 ) AND ad.id IS NULL
		THEN ''
		ELSE 'erro' END OAB,
		CASE WHEN 
		((select count(id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where id_pessoa = l.id_usuario AND cd_tp_documento_identificacao = 'CPJ' and length(nr_documento_identificacao) = 18) > 0 ) AND jr.id_pessoa_juridica IS NOT NULL
		OR
		((select count(id_pessoa_doc_identificacao) from client.tb_pess_doc_identificacao where id_pessoa = l.id_usuario AND cd_tp_documento_identificacao = 'CPJ') = 0 ) AND jr.id_pessoa_juridica IS NULL
		THEN ''
		ELSE 'erro' END CNPJ,
		CASE WHEN di.id_pessoa IS NULL THEN '' 
		WHEN di.id_pessoa IS NOT NULL AND di.cd_tp_documento_identificacao IS NOT NULL THEN di.cd_tp_documento_identificacao ELSE 'erro' END tp_doc,
		CASE WHEN di.id_pessoa IS NULL THEN '' 
		WHEN di.id_pessoa IS NOT NULL AND di.nr_documento_identificacao IS NOT NULL THEN di.nr_documento_identificacao ELSE 'erro' END nr_documento,
		CASE WHEN di.in_ativo IS NULL THEN ''
		WHEN di.in_ativo = 't' THEN 'Ativo' ELSE 'inativo' END doc_status,


		--PESSOA FISICA
		CASE WHEN pf.id_pessoa_fisica IS NULL THEN '' 
		WHEN pf.id_pessoa_fisica IS NOT NULL AND pf.in_sexo IS NOT NULL AND length(pf.in_sexo) = 1  THEN '' ELSE 'erro' END genero,
		CASE WHEN pf.id_pessoa_fisica IS NULL THEN '' 
		WHEN pf.id_pessoa_fisica IS NOT NULL AND pf.dt_nascimento IS NOT NULL THEN '' ELSE 'erro' END dt_nascimento,
		CASE WHEN pf.id_pessoa_fisica IS NULL THEN '' 
		WHEN pf.id_pessoa_fisica IS NOT NULL AND pf.nm_genitora IS NOT NULL AND length(pf.nm_genitora) > 1  THEN '' ELSE 'erro' END nome_mae,
		CASE WHEN pf.id_pessoa_fisica IS NULL THEN '' --nao é pessoa fisica
		WHEN pf.id_pessoa_fisica IS NOT NULL 
		AND ad.id IS NOT NULL --é advogado
		AND pf.nr_ddd_celular IS NOT NULL 
		AND length(pf.nr_ddd_celular) > 1 
		AND pf.nr_celular IS NOT NULL 
		AND length(pf.nr_celular) >=8  
		THEN ''

		WHEN pf.id_pessoa_fisica IS NOT NULL 
		AND ad.id IS NOT NULL --é advogado e procurador
		AND pr.id IS NOT NULL
		AND pf.nr_ddd_celular IS NOT NULL 
		AND length(pf.nr_ddd_celular) > 1 
		AND pf.nr_celular IS NOT NULL 
		AND length(pf.nr_celular) >=8  
		THEN ''
		WHEN pf.id_pessoa_fisica IS NOT NULL 
		AND pr.id IS NOT NULL 
		THEN '' --é procurador

		WHEN pf.id_pessoa_fisica IS NOT NULL --é pessoa fisica
		AND pf.nr_ddd_celular IS NOT NULL 
		AND length(pf.nr_ddd_celular) > 1 
		AND pf.nr_celular IS NOT NULL 
		AND length(pf.nr_celular) >=8  
		THEN '' 

		ELSE 'erro' END tel_cel,
		CASE WHEN pf.id_pessoa_fisica IS NULL THEN '' 
		WHEN pf.id_pessoa_fisica IS NOT NULL AND pf.id_municipio_nascimento IS NOT NULL THEN '' ELSE 'erro' END uf_nasc,
		CASE WHEN pf.id_pessoa_fisica IS NULL THEN ''
		WHEN pf.id_pessoa_fisica IS NOT NULL AND pf.id_pais IS NOT NULL THEN '' ELSE 'erro' END pais,
		CASE WHEN pf.id_pessoa_fisica IS NULL THEN '' 
		WHEN pf.id_pessoa_fisica IS NOT NULL AND pf.in_especializacoes IS NOT NULL THEN '' ELSE 'erro' END especializacao,
		--PESSOA JURIDICA
		CASE WHEN jr.id_pessoa_juridica IS NULL THEN '' 
		WHEN jr.id_pessoa_juridica IS NOT NULL AND jr.nm_fantasia IS NOT NULL THEN '' ELSE 'erro' END nome_fantasia,
		--PROCURADOR
		CASE WHEN pr.id IS NULL THEN '' 
		WHEN pr.id IS NOT NULL AND pr.id_procuradoria IS NOT NULL THEN (SELECT ds_nome from client.tb_procuradoria where id_procuradoria = pr.id_procuradoria) ELSE 'erro' END nome_procuradoria,
		--PUSH
		CASE WHEN psh.id_pessoa_push IS NULL THEN '' 
		WHEN psh.id_pessoa_push IS NOT NULL AND psh.ds_email IS NOT NULL THEN psh.ds_email ELSE 'erro' END push_email,
		CASE WHEN psh.id_pessoa_push IS NULL THEN '' 
		WHEN psh.id_pessoa_push IS NOT NULL AND psh.nr_cep IS NOT NULL THEN psh.nr_cep ELSE 'erro' END push_cep,
		CASE WHEN psh.id_pessoa_push IS NULL THEN '' 
		WHEN psh.id_pessoa_push IS NOT NULL AND psh.ds_endereco IS NOT NULL THEN psh.ds_endereco ELSE 'erro' END push_endereco,
		CASE WHEN psh.id_pessoa_push IS NULL THEN '' 
		WHEN psh.id_pessoa_push IS NOT NULL AND psh.id_municipio IS NOT NULL THEN psh.ds_bairro ELSE 'erro' END push_bairro,
		CASE WHEN psh.id_pessoa_push IS NULL THEN '' 
		WHEN psh.id_pessoa_push IS NOT NULL AND psh.ds_bairro IS NOT NULL THEN '' ELSE 'erro' END push_municipio,
		CASE WHEN psh.id_pessoa_push IS NULL THEN '' 
		WHEN psh.id_pessoa_push IS NOT NULL AND psh.nr_ddd_telefone IS NOT NULL THEN psh.nr_ddd_telefone ELSE 'erro' END push_ddd_telefone,
		CASE WHEN psh.id_pessoa_push IS NULL THEN '' 
		WHEN psh.id_pessoa_push IS NOT NULL AND psh.nr_ddd_telefone IS NOT NULL THEN psh.nr_telefone ELSE 'erro' END push_telefone,
		--ENDERECO
		CASE WHEN (SELECT COUNT (nm_logradouro) from core.tb_endereco where id_usuario = l.id_usuario AND id_cep <> 874042) > 0 THEN '' ELSE 'ERRO' END endereço,

		l.ds_nome

		from acl.tb_usuario_login l

		LEFT JOIN client.tb_pessoa_fisica pf ON (l.id_usuario = pf.id_pessoa_fisica) -- verifica se está cadastrado como PF
		LEFT JOIN client.tb_pessoa_advogado ad ON (l.id_usuario = ad.id) -- verifica se está cadastrado como ADV
		LEFT JOIN client.tb_pessoa_assistente_adv assisAdv ON (l.id_usuario = assisAdv.id) -- verifica se está cadastrado como assistente ADV
		LEFT JOIN client.tb_pessoa_autoridade pessAutor ON (l.id_usuario = pessAutor.id_pessoa_autoridade) -- verifica se está cadastrado como pessoa autoridade
		LEFT JOIN client.tb_pessoa_magistrado mag ON (l.id_usuario = mag.id) -- verifica se está cadastrado como magistrado
		LEFT JOIN client.tb_pessoa_oficial_justica ofjus ON (l.id_usuario = ofjus.id) -- verifica se está cadastrado como oficial de justica
		LEFT JOIN client.tb_pessoa_servidor serv ON (l.id_usuario = serv.id) -- verifica se está cadastrado como servidor
		LEFT JOIN client.tb_pessoa_juridica jr ON (l.id_usuario = jr.id_pessoa_juridica) -- verifica se está cadastrado como PJ
		LEFT JOIN client.tb_pess_doc_identificacao di ON (di.id_pessoa = l.id_usuario) -- verifica quais documentos estão cadastrados
		LEFT JOIN client.tb_pessoa_procurador pr ON (pr.id = l.id_usuario) -- verifica se está cadastrado como procurador
		LEFT JOIN client.tb_pessoa_push psh ON (psh.id_pessoa_push = l.id_usuario) -- verifica se está cadastrado no push
		LEFT JOIN client.tb_pessoa_localizacao pl ON (pl.id_pessoa = l.id_usuario) -- tabela de localizações da pessoa
		LEFT JOIN core.tb_usuario_localizacao ul ON (ul.id_usuario = l.id_usuario) -- tabela de localizações do usuário
		LEFT JOIN core.tb_localizacao loc ON (loc.id_localizacao = pl.id_localizacao OR loc.id_localizacao = ul.id_localizacao) -- tabela de nomes de localizações dos usuários
		LEFT JOIN client.tb_pessoa pes ON (l.id_usuario = pes.id_pessoa) -- verifica cadastro de pessoa fisica

		JOIN DADOS_PESSOA_TEMP DPT ON
		                (
		                               1=0
		                               OR upper(l.ds_nome) like upper('%' || DPT.nome_pessoa || '%') -- NOME
		                               OR upper(di.ds_nome_pessoa) like upper('%' || DPT.nome_pessoa || '%') -- NOME NO DOCUMENTO
		                               OR regexp_replace(di.nr_documento_identificacao, '[\.//-]*', '', 'g') LIKE '%' || regexp_replace(DPT.cpf_pessoa, '[\.//-]*', '', 'g') ||'%' -- CPF/CNPJ
		                               OR regexp_replace(l.ds_login, '[\.//-]*', '', 'g') LIKE '%'|| regexp_replace(DPT.cpf_pessoa, '[\.//-]*', '', 'g') || '%' -- CPF/CNPJ no login
		                               OR di.nr_documento_identificacao = DPT.oab_pessoa -- OAB
		                               OR upper(l.ds_email) like upper('%' || DPT.email_pessoa || '%') -- EMAIL
		                )
		WHERE 
		                1=1
		--            OR l.id_usuario IN (7799, 7803,7802 )
		ORDER BY l.id_usuario
		limit 100;

		-- SCRIPT RESPONSAVEL POR RETIRAR A DUPLICIDADE DO USUARIO 'RAPHAEL CAPELLETI VITAGLIANO' NO SISTEMA PJe
		BEGIN;

		DELETE
		FROM TB_USUARIO_PAPEL
		WHERE ID_USUARIO IN (83932); -- ID A SER SUBSTITUIDO - VERIFICAR SE E PARTE EM ALGUM PROCESSO
		
		DELETE
		FROM TB_USUARIO_LOCALIZACAO
		WHERE ID_USUARIO IN (83932);
		
		DELETE
		FROM TB_BLOQUEIO_USUARIO
		WHERE ID_USUARIO IN (83932);
		
		DELETE
		FROM TB_PESS_PROCRDOR_PRCRDORIA
		WHERE ID_PESS_PROCURADORIA_ENTIDADE IN
		    ( SELECT ID_PESS_PROCURADORIA_ENTIDADE
		     FROM TB_PESS_PRCRDORIA_ENTIDADE
		     WHERE ID_PESSOA IN (83932));
		
		DELETE
		FROM TB_PESS_PRCRDORIA_ENTIDADE
		WHERE ID_PESSOA IN (83932);
		
		UPDATE TB_ENDERECO
		SET ID_USUARIO = 78525   
		WHERE ID_USUARIO IN (83932);
		
		UPDATE TB_PROC_PARTE_EXPEDIENTE
		SET ID_PESSOA_PARTE = 78525   
		WHERE ID_PESSOA_PARTE IN (83932);
		
		UPDATE TB_PROC_PARTE_EXPEDIENTE
		SET ID_PESSOA_CIENCIA = 78525   
		WHERE ID_PESSOA_CIENCIA IN (83932);
		
		DELETE
		FROM TB_PROCESSO_PARTE_ENDERECO
		WHERE ID_PROCESSO_PARTE IN
		    ( SELECT ID_PROCESSO_PARTE
		     FROM TB_PROCESSO_PARTE
		     WHERE ID_PESSOA IN (83932)
		       AND IN_SITUACAO <> 'A');
		
		DELETE
		FROM TB_PROCESSO_PARTE
		WHERE ID_PESSOA IN (83932)
		  AND IN_SITUACAO <> 'A';
		
		UPDATE TB_PROCESSO_PARTE PP
		SET ID_PESSOA = 78525   
		WHERE ID_PESSOA IN (83932)
		  AND NOT EXISTS
		    ( SELECT 1
		     FROM TB_PROCESSO_PARTE PP2
		     WHERE PP2.ID_PROCESSO_TRF = PP.ID_PROCESSO_TRF
		       AND PP2.ID_PESSOA = 78525   
		       AND PP2.ID_TIPO_PARTE <> 7);
		
		UPDATE TB_PROCESSO_PARTE_ENDERECO END1
		SET ID_PROCESSO_PARTE = PP2.ID_PROCESSO_PARTE
		FROM TB_PROCESSO_PARTE_ENDERECO END2
		INNER JOIN TB_PROCESSO_PARTE PP ON END2.ID_PROCESSO_PARTE = PP.ID_PROCESSO_PARTE
		AND PP.ID_PESSOA IN (83932)
		INNER JOIN TB_PROCESSO_PARTE PP2 ON PP2.ID_PROCESSO_TRF = PP.ID_PROCESSO_TRF
		AND PP2.ID_PESSOA = 78525   
		WHERE END2.ID_PROCESSO_PARTE_ENDERECO = END1.ID_PROCESSO_PARTE_ENDERECO;
		
		DELETE
		FROM TB_PROCESSO_PARTE
		WHERE ID_PESSOA IN (83932 );
		
		UPDATE TB_PROC_PARTE_REPRESNTANTE PPR
		SET ID_REPRESENTANTE = 78525   
		WHERE ID_REPRESENTANTE IN (83932);
		
		UPDATE TB_PROC_AUDIENCIA_PESSOA
		SET ID_PESSOA = 78525   
		WHERE ID_PESSOA IN (83932);
		
		UPDATE TB_PROC_VISIBILIDA_SEGREDO PVS
		SET ID_PESSOA = 78525   
		WHERE ID_PESSOA IN (83932)
		  AND NOT EXISTS
		    ( SELECT 1
		     FROM TB_PROC_VISIBILIDA_SEGREDO PVS2
		     WHERE PVS2.ID_PROCESSO_TRF = PVS.ID_PROCESSO_TRF
		       AND PVS2.ID_PESSOA = 78525   );
		
		DELETE
		FROM TB_PROC_VISIBILIDA_SEGREDO PVS
		WHERE ID_PESSOA IN (83932);
		
		UPDATE TB_PROCESSO_TRF
		SET ID_PESSOA_MARCOU_REVISADO = 78525   
		WHERE ID_PESSOA_MARCOU_REVISADO IN (83932);
		
		UPDATE TB_PROCESSO_TRF
		SET ID_PESSOA_MARCOU_PAUTA = 78525   
		WHERE ID_PESSOA_MARCOU_PAUTA IN (83932);
		
		UPDATE TB_PROCESSO_TRF
		SET ID_PESSOA_MARCOU_JULGAMENTO = 78525   
		WHERE ID_PESSOA_MARCOU_JULGAMENTO IN (83932);
		
		UPDATE TB_PROCESSO_TRF
		SET ID_PESSOA_RELATOR_PROCESSO = 78525   
		WHERE ID_PESSOA_RELATOR_PROCESSO IN (83932);
		
		UPDATE TB_PROCESSO_TRF
		SET ID_PES_APRECIOU_JUS_GRATUITA = 78525   
		WHERE ID_PES_APRECIOU_JUS_GRATUITA IN (83932);
		
		UPDATE TB_DOCUMENTO_PESSOA
		SET ID_PESSOA = 78525   
		WHERE ID_PESSOA IN (83932);
		
		UPDATE TB_MEIO_CONTATO
		SET ID_PESSOA = 78525   
		WHERE ID_PESSOA IN (83932);
		
		UPDATE TB_PESSOA_NOME_ALTERNATIVO
		SET ID_PESSOA = 78525   
		WHERE ID_PESSOA IN (83932);
		
		UPDATE TB_PESS_DOC_IDENTIFICACAO
		SET ID_PESSOA = 78525   
		WHERE ID_PESSOA IN (83932);
		
		UPDATE TB_AUTORIDADE_PUBLICA
		SET ID_PESSOA = 78525   
		WHERE ID_PESSOA IN (83932);
		
		UPDATE TB_AUTORIDADE_AFETADA
		SET ID_PESSOA_AUTORIDADE = 78525   
		WHERE ID_PESSOA_AUTORIDADE IN (83932);
		
		DELETE
		FROM TB_PESSOA_AUTORIDADE
		WHERE ID_PESSOA_AUTORIDADE IN (83932);
		
		DELETE
		FROM TB_PESSOA_ASSISTENTE_ADV
		WHERE ID IN (83932);
		
		DELETE
		FROM TB_PESSOA_ADVOGADO
		WHERE ID IN (83932);
		
		DELETE
		FROM TB_PESSOA_MAGISTRADO
		WHERE ID IN (83932);
		
		DELETE
		FROM TB_PESSOA_OFICIAL_JUSTICA
		WHERE ID IN (83932);
		
		DELETE
		FROM TB_PESSOA_PERITO
		WHERE ID IN (83932);
		
		DELETE
		FROM TB_PESSOA_PROCURADOR
		WHERE ID IN (83932);
		
		DELETE
		FROM TB_PESSOA_SERVIDOR
		WHERE ID IN (83932);
		
		DELETE
		FROM TB_PESSOA_FISICA
		WHERE ID_PESSOA_FISICA IN (83932);
		
		DELETE
		FROM TB_PESSOA_JURIDICA
		WHERE ID_PESSOA_JURIDICA IN (83932);
		
		DELETE
		FROM TB_PESSOA
		WHERE ID_PESSOA IN (83932);
		
		DELETE 
		FROM TB_PROC_PARTE_EXPEDIENTE
		WHERE ID_PESSOA_PARTE IN (83932);
		
		UPDATE TB_DOCUMENTO_PESSOA
		SET ID_USUARIO_CADASTRO = 78525   
		WHERE ID_USUARIO_CADASTRO IN (83932) ;
		
		DELETE
		FROM TB_USUARIO
		WHERE ID_USUARIO IN (83932);
		
		DELETE
		FROM TB_USUARIO_LOGIN
		WHERE ID_USUARIO IN (83932);

	COMMIT;

---------------------------------------------------------------------
# POSTGRES
---------------------------------------------------------------------

	# INSTALAR 'POSTGRES'
		$ sudo apt install postgresql postgresql-common
	
	# ACESSAR POSTGRES VIA TERMINAL
		$ psql -h zincoh02.cnj.jus.br -U usuariohoml -d pje_cnj_prod  -p 5432
		$ psql -h 172.20.18.73 -U postgres -d pje_cnj_prod  -p 5432
		$ psql -h 172.20.18.73 -U postgres
			> Senha: admin
			> \l                 // LISTAR TODOS OS DATABASES

	# REALIZAR DUMP DE UMA BASE DE DADOS
		$ pg_dump pje_cnj_prod -h zincoh02.cnj.jus.br -U usuariohoml > /home/desenvolvimento/Documentos/PJE_CNJ_PROD_2018_10_001_DUMP.SQL
		
---------------------------------------------------------------------
# PROCEDIMENTOS LINUX
---------------------------------------------------------------------
								 
	## INSTALACAO DE COMPONENTES EXTRAS DO LINUX
		$ sudo apt-get install ubuntu-restricted-addons ubuntu-restricted-extras
								 
	## INICIAR SERVICO DO BANCO DE DADOS 'H2 DATABASE'
		
		# ACESSAR ARQUIVO 'BIN/h2.sh'
			$ chmod +x h2.sh
			$ ./h2.sh 

	## CONFIGURAR IDEAINTELIJJ (LICENÇA)

		$ ACESSAR ENDERECO
			$ https://www.jetbrains.tools/

	## DEFINIR CARACTERES NO LINUX MINT
		$ gsettings set org.gnome.meld detect-encodings "['utf8','latin1']"

	## DESINSTALAR LIBREOFFICE

		$ sudo apt-get remove --purge libreoffice*

	## INSTALAR MAVEN ( NO LINUX DEEPING - https://www.javahelps.com/2017/10/install-apache-maven-on-linux.html )
		$ 
	
	## INSTALAR JAVA (ORACLE)
		$ sudo add-apt-repository ppa:webupd8team/java
		$ sudo apt-get update
		$ sudo apt-get install oracle-java8-installer
		$ java -version
		$ sudo apt-get install oracle-java8-set-default

		$ sudo apt install software-properties-common dirmngr
		$ sudo add-apt-repository ppa:webupd8team/java sudo apt update
		$ apt-get install oracle-java8-installer
		$ java -version
		$ sudo update-alternatives --config java

	## REMOVER INSTALACAO JAVA (ORACLE)

		$ sudo apt-get install ppa-purge -y
		$ sudo ppa-purge ppa:webupd8team/java
		$ sudo apt-get update
		$ sudo apt-get autoremove
		$ sudo apt-get autoclean
		$ sudo apt-get update && sudo apt-get autoclean && sudo apt-get autoremove && sudo apt update && sudo apt autoclean && sudo apt autoremove  

	## REMOVER INSTALACAO DO JAVA DO ORACLE

		$ sudo apt-get install ppa-purge -y       -- NAO FUNCIONA NO LINUX DEEPIN
		$ sudo ppa-purge ppa:webupd8team/java
		$ sudo apt-get update
		$ sudo apt-get autoremove

	## REMOVER INSTALACAO DO OPENJDK
    
        $ sudo apt-get purge openjdk*
        
    ## REMOVER INSTALACAO DO RHYTMIBOX
    
        $ sudo apt-get remove rhythmbox

	## GERENCIAR VARIAS INSTANCIAS DO MOZILLA FIREFOX [IMPLEMENTAR]

	## TEMAS MACOS (ATE A VERSÃO 18.3 DO MINT)

		$ sudo add-apt-repository ppa:noobslab/macbuntu
		$ sudo apt update
		$ sudo apt install macbuntu-os-icons-lts-v7 macbuntu-os-ithemes-lts-v7

	## PESQUISAR RECURSIVAMENTE POR UM ARQUIVO EM UM DIRETÓRIO
		$ find -name "*.*" -exec grep -Hin "zincod01" {} \;

	## CRIAR LANÇADORES (ATALHOS) I	

		$ CRIAR ARQUIVO 'nomeLancador.desktop' NA PASTA '/home/desenvolvimento/.local/share/applications' ou '~/.local/share/applications'
		$ cd ~/.local/share/applications
		$ EDITAR ARQUIVO COM OS CAMINHOS DOS PROGRAMAS
		$ VERIFICAR NA BARRA DE PESQUISAS SE EXISTE O LANCADOR 

	## CRIAR LANÇADORES (ATALHOS) II
	
		-- CRIAR ARQUIVO (GERAR_LANCADORES.SH)	

			------------------------------------------------------------------------------------------------------------------
				#!/bin/sh
				# Add to applications list
				cat << EOF > ~/.local/share/applications/Word_WSP.desktop
				[Desktop Entry]
				Name=Word WPS
				Exec=/home/desenvolvimento/Desenvolvimento/ALEF/z_WPS/2_WORLD
				MimeType=text/plain;
				Terminal=false
				Type=Application
				Icon=/home/desenvolvimento/Desenvolvimento/ALEF/z_WPS/resource/icons/hicolor/256x256/apps/wps-office-wpsmain.png
				Categories=Development;
				EOF
				chmod a+x ~/.local/share/applications/Word_WSP.desktop
			------------------------------------------------------------------------------------------------------------------

		-- EXECUTAR COM O ARQUIVO

			$ chmod a+x GERAR_LANCADORES.SH 
			$ ./GeradorLancadores.sh

		-- VERIFICAR SE FORAM CRIADOS CORRETAMENTE

			$ cd /home/desenvolvimento/.local/share/applications

	## COMANDOS DIVERSOS

		$ sudo dpkg --configure -a
		$ sudo apt install <programa>
		$ sudo apt upgrade

	## SIMULAR 'SPOTFY'

		$ chromium-browser --app=http://streamsquid.com/

	## INSERIR CERTIFICADO DIGITAL NO SISTEMA

		$ openssl x509 -inform DER -in certnew.cer -out certnew.crt
		$ sudo mkdir /usr/share/ca-certificates/extra
		$ sudo cp certnew.crt /usr/share/ca-certificates/extra/certnew.crt
		$ sudo dpkg-reconfigure ca-certificates

	## SENHA CERTIFICADO DIGITAL 

		> TAYNER
			> T@yner1020

	## DESABILITAR 

		$ mkdir disabled
		$ mkdir disabled/features disabled/plugins
		$ mv plugins/org.eclipse.jpt.* disabled/plugins
		$ mv features/org.eclipse.jpt.* disabled/features

	## PERMISSAO TOTAL A UM DIRETORIO

		$ sudo chmod -R 777 /home/desenvolvimento/Desenvolvimento

	## INSTALAR PROGRAMA 'DOCKY' (BARRA DE FERRAMENTAS)

		$ sudo apt-get update
		$ sudo apt-get install docky	

	## CONVERTER '.RPM' EM '.DEB'

		$ sudo apt-get install alien <NOME_ARQUIVO.RPM>
		$ sudo alien jdk-10.0.2_linux-x64_bin.rpm --to-deb
		$ sudo alien --to-deb 
		$ sudo alien --to-rpm
		$ sudo alien --to-tgz

---------------------------------------------------------------------
# DEMANDAS VIA SCRIPT
---------------------------------------------------------------------

---------------------------------------------------------------------
# DIARIO DE BORDO
---------------------------------------------------------------------

		## 14/08/2018 - TERCA

			# BASIS-50498 - https://sgo.basis.com.br/browse/BASIS-50498			 [PROCRASTINADO]
				> UNIFICAR USUARIO


		## 15/08/2018 - QUARTA

			# BASIS-52983 - https://sgo.basis.com.br/browse/BASIS-52983 		 [PROCRASTINADO]	
				> PRAZO PARA MANIFESTACAO			
			# BASIS-53074 - https://sgo.basis.com.br/browse/BASIS-53074 		 [PROCRASTINADO]
				> FECHAR TAREFAS DO PROCESSO '5105-55'
			# BASIS-53077 - https://sgo.basis.com.br/browse/BASIS-53077 		 [PROCRASTINADO]
				> FECHAR TAREFAS DO PROCESSO '1393-62'
			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'.  		 [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA APRESENTAR ERRO PARA SER FECHADA     [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA SER INICIADA AUTOMÁTICAMENTE         [PROCRASTINADO]
			# [JOSE]      - SUBIR WILDFLY EM DOIS AMBIENTES   					 [PROCRASTINADO]
			# [JOSE]      - CONFIGURAR ASSINADOR DIGITAL PARA FIREFOX            [PROCRASTINADO]
			# [BRUNO] FECHAR PAUTA DA SESSAO DO DIA 21/08 COM 115 PROCESSOS      [FECHADO]


		## 16/08/2018 - QUINTA

			# BASIS-53074 - https://sgo.basis.com.br/browse/BASIS-53074 		 [FECHADO]
				> ABRIR TAREFAS DO PROCESSO '5105-55'

			# [BRUNO]     - FAZER CHERRY-PICK PARA TESTE EXTERNO                 [FECHADO] 
				> BRANCH PJEVII-2664 - http://www.cnj.jus.br/jira/browse/PJEVII-2664
						> https://git.cnj.jus.br/pje/pje/merge_requests/new/diffs?merge_request%5Bsource_branch%5D=PJEVII-2664
					> BRANCH 2.0.0.7_cnj  [FECHADO]
					> BRANCH 2.0.0.8_cnj  [AGUARDANDO]
						> CRIAR BRANCH A PARTIR DA TAG '2.0.0.8'	

			# BASIS-53077 - https://sgo.basis.com.br/browse/BASIS-53077 		 [PROCRASTINADO]
				> ABRIR TAREFAS DO PROCESSO '1393-62' ('MINUTAR ATO')

			# PJEVII-1368 - http://www.cnj.jus.br/jira/browse/PJEVII-1368   	 [PROCRASTINADO]
				> PADRONIZAÇÃO DAS TELAS DE CONTROLE DE AR. GERAR EVIDENCIAS.
			# PJEVII-1696 - http://www.cnj.jus.br/jira/browse/PJEVII-1696        [PROCRASTINADO]
				> AJUSTAR REGRAS DE APTIDÃO. FLUXOS. GERAR EVIDENCIAS.
			# BASIS-50498 - https://sgo.basis.com.br/browse/BASIS-50498			 [PROCRASTINADO]
				> UNIFICAR USUARIO. EXECUTAR EM PRODUÇÃO

			# [JOSE]      - CONFIGURAR ASSINADOR DIGITAL PARA FIREFOX            [PROCRASTINADO]		
			# BASIS-52983 - https://sgo.basis.com.br/browse/BASIS-52983 		 [PROCRASTINADO]	
				> PRAZO PARA MANIFESTACAO APARECE. NAO DEVE APARECER. INVESTIGAR.	
			
			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'.  		 [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA APRESENTAR ERRO PARA SER FECHADA     [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA SER INICIADA AUTOMÁTICAMENTE         [PROCRASTINADO]
			# [JOSE]      - SUBIR WILDFLY EM DOIS AMBIENTES                      [PROCRASTINADO]			
			# [BRUNO]      - VERIFICAR PROBLEMA DE MINUTA EM ELABORACAO          [PROCRASTINADO]
				> VERIFICAR ORIGEM DO PROBLEMA
				> IDENTIFICAR ISSUE PARA ESSE TIPO DE PROBLEMA
				> CORRIGIR FETIVAMENTE O PROBLEMA

 
		## 17/08/2018 - SEXTA

			# BASIS-53077 - https://sgo.basis.com.br/browse/BASIS-53077 		 [FECHADO]
				> ABRIR TAREFAS DO PROCESSO '1393-62' ('MINUTAR ATO')
			# [JOSE]      - CONFIGURAR ASSINADOR DIGITAL PARA FIREFOX            [FECHADO]

			# PJEVII-1368 - http://www.cnj.jus.br/jira/browse/PJEVII-1368   	 [PROCRASTINADO]
				> PADRONIZAÇÃO DAS TELAS DE CONTROLE DE AR. GERAR EVIDENCIAS.
			# PJEVII-1696 - http://www.cnj.jus.br/jira/browse/PJEVII-1696        [PROCRASTINADO]
				> AJUSTAR REGRAS DE APTIDÃO. FLUXOS. GERAR EVIDENCIAS.
			# BASIS-50498 - https://sgo.basis.com.br/browse/BASIS-50498			 [PROCRASTINADO]
				> UNIFICAR USUARIO. EXECUTAR EM PRODUÇÃO

					
			# BASIS-52983 - https://sgo.basis.com.br/browse/BASIS-52983 		 [PROCRASTINADO]	
				> PRAZO PARA MANIFESTACAO APARECE. NAO DEVE APARECER. INVESTIGAR.	
			
			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'.  		 [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA APRESENTAR ERRO PARA SER FECHADA     [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA SER INICIADA AUTOMÁTICAMENTE         [PROCRASTINADO]
			# [JOSE]      - SUBIR WILDFLY EM DOIS AMBIENTES                      [PROCRASTINADO]			
			# [BRUNO]      - VERIFICAR PROBLEMA DE MINUTA EM ELABORACAO          [PROCRASTINADO]
				> VERIFICAR ORIGEM DO PROBLEMA
				> IDENTIFICAR ISSUE PARA ESSE TIPO DE PROBLEMA
				> CORRIGIR FETIVAMENTE O PROBLEMA
			# [PC-1414] - http://www.cnj.jus.br/jira/browse/PC-1414              [PROCRASTINADO]
				> IMPLEMENTAR CONTROLE DE VISIBILIDADE DO RIBENA


		## 20/08/2018 - SEGUNDA

			# [BRUNO] 'SESSÃO CONTINUA'                                          [PROCRASTINADO]
				> (VIRTUAL) EXECUTA JOB ANTES DA DATA PREVISTA
					> CORRIGIR PROBLEMA

			# [TAYNER] MOVIMENTAÇÃO DO PROCESSOS ADIADOS DEVEM ESTAR NA          [PROCRASTINADO]
				> DATA CORRETA, POIS FOI GERADO RETROATIVAMENTE.
			    > ALTERAR A DATA PARA 113 PROCESSOS REFERENTE A SESSAO ''

			# BASIS-52983 - https://sgo.basis.com.br/browse/BASIS-52983 		 [PROCRASTINADO]	
				> PRAZO PARA MANIFESTACAO APARECE. NAO DEVE APARECER. INVESTIGAR.
			
			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'.  		 [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA APRESENTAR ERRO PARA SER FECHADA     [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA SER INICIADA AUTOMÁTICAMENTE         [PROCRASTINADO]

			# [JOSE]      - SUBIR WILDFLY EM DOIS AMBIENTES                      [PROCRASTINADO]		

			# [PJEVII-2542] https://git.cnj.jus.br/pje/pje/tree/PJEVII-2542      [FECHADO]
				> REALIZAR CHERRY-PICK DA DEMANDA					

			# [BRUNO]      - VERIFICAR PROBLEMA DE MINUTA EM ELABORACAO          [PROCRASTINADO]
				> VERIFICAR ORIGEM DO PROBLEMA
				> IDENTIFICAR ISSUE PARA ESSE TIPO DE PROBLEMA
				> CORRIGIR FETIVAMENTE O PROBLEMA

			# [PC-1414] - http://www.cnj.jus.br/jira/browse/PC-1414              [PROCRASTINADO]
				> IMPLEMENTAR CONTROLE DE VISIBILIDADE DO RIBENA
					> PJEVII-2664
					> https://sgo.basis.com.br/browse/BASIS-53625                [PROCRASTINADO]
					> https://sgo.basis.com.br/browse/BASIS-53626                [PROCRASTINADO]
					> https://sgo.basis.com.br/browse/BASIS-53627                [PROCRASTINADO]
						> Baixar branch
						> Fazer Rebase (sincronizar com a master)
						> Push (subir branch atualizado com a master)
						> Criar MR  
						> Cherry-pick (para a versão 0.8) 

							> http://www.oabsp.org.br/sobre-oabsp/grandes-causas/a-comunista
							> http://www.caixa.gov.br/Paginas/home-caixa.aspx
							> http://www.tse.jus.br/eleicoes/eleicoes-2018/informacoes-sobre-as-eleicoes-2018
							> https://www.stm.jus.br/
							> http://portal.cfm.org.br/

			# [QUINTIN]  											             [PROCRASTINADO]
				> MARCAR CONSULTAS PARA
					> OTORRINO
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
				> ESTUDAR 
					> CLDF
					> COMPUTAÇÃO	

				> ALTERAR DATA DA CERTIFICACAO									 [FECHADO]
					> NÃO É POSSÍVEL. PROMOÇÃO VENCE EM 31/08/2018
						> REALIZAR PROVA DIA 28/08/2018


		## 22/08/2018 - QUARTA

			# BASIS-52983 - https://sgo.basis.com.br/browse/BASIS-52983 		 [HOMOLOGAR]	
				> PRAZO PARA MANIFESTACAO APARECE. NAO DEVE APARECER. INVESTIGAR.
					> REALIZADO A CORREÇÃO VIA SCRIPT
						> DEVE-SE REALIZAR A IDENTIFICAÇÃO E CORREÇÃO DO ERRO    

			# [PC-1415] http://www.cnj.jus.br/jira/browse/PC-1415                [HOMOLOGAR]
				> ALTERAR MOVIMENTOS DA SESSÃO DE JULGAMENTO			
					> ALTERAR A DATA PARA 136 PROCESSOS REFERENTE A SESSAO
					  POIS FOI GERADO RETROATIVAMENTE.

			# [BRUNO] 'SESSÃO CONTINUA'                                          [PROCRASTINADO]
				> (VIRTUAL) EXECUTA JOB ANTES DA DATA PREVISTA
					> CORRIGIR PROBLEMA

			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'.  		 [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA APRESENTAR ERRO PARA SER FECHADA     [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA SER INICIADA AUTOMÁTICAMENTE         [PROCRASTINADO]

			# [JOSE]      - SUBIR WILDFLY EM DOIS AMBIENTES                      [PROCRASTINADO]	

			# [JOSE]      - ASSINAR DOCUMENTOS MODO TESTE PJE                    [FECHADO]				

			# [BRUNO]      - VERIFICAR PROBLEMA DE MINUTA EM ELABORACAO          [PROCRASTINADO]
				> VERIFICAR ORIGEM DO PROBLEMA
				> IDENTIFICAR ISSUE PARA ESSE TIPO DE PROBLEMA
				> CORRIGIR FETIVAMENTE O PROBLEMA

			# [PC-1414] - http://www.cnj.jus.br/jira/browse/PC-1414              [PROCRASTINADO]
				> IMPLEMENTAR CONTROLE DE VISIBILIDADE DO RIBENA
					> PJEVII-2664
					> https://sgo.basis.com.br/browse/BASIS-53625                [FECHADO]
					> https://sgo.basis.com.br/browse/BASIS-53626                [EM EXECUCAO]
					> https://sgo.basis.com.br/browse/BASIS-53627                [FECHADO]
						> Baixar branch
						> Fazer Rebase (sincronizar com a master)
						> Push (subir branch atualizado com a master)
						> Criar MR  
						> Cherry-pick (para a versão 0.8) 

							> http://www.oabsp.org.br/sobre-oabsp/grandes-causas/a-comunista
							> http://www.caixa.gov.br/Paginas/home-caixa.aspx
							> http://www.tse.jus.br/eleicoes/eleicoes-2018/informacoes-sobre-as-eleicoes-2018
							> https://www.stm.jus.br/
							> http://portal.cfm.org.br/

			# [QUINTIN]  											             [PROCRASTINADO]
				> MARCAR CONSULTAS PARA
					> OTORRINO
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS

				> [ESPOSA]														  [FECHADO]
					> IMPRIMIR LOCAL PROVA PARA JAMILLEH


		## 23/08/2018 - QUINTA

			# BASIS-52983 - https://sgo.basis.com.br/browse/BASIS-52983 		 [HOMOLOGAR]	
				> PRAZO PARA MANIFESTACAO APARECE. NAO DEVE APARECER. INVESTIGAR.
					> REALIZADO A CORREÇÃO VIA SCRIPT
						> DEVE-SE REALIZAR A IDENTIFICAÇÃO E CORREÇÃO DO ERRO    

			# [PC-1415] http://www.cnj.jus.br/jira/browse/PC-1415                [HOMOLOGAR]
				> ALTERAR MOVIMENTOS DA SESSÃO DE JULGAMENTO			
					> ALTERAR A DATA PARA 136 PROCESSOS REFERENTE A SESSAO
					  POIS FOI GERADO RETROATIVAMENTE.
					  > SERÁ COLOCADO EM UMA SPRINT

			# [PC-1414] - http://www.cnj.jus.br/jira/browse/PC-1414              [HOMOLOGAR]
				> IMPLEMENTAR CONTROLE DE VISIBILIDADE DO RIBENA
					> PJEVII-2664
					> https://sgo.basis.com.br/browse/BASIS-53625                [FECHADO]
					> https://sgo.basis.com.br/browse/BASIS-53626                [HOMOLOGAR]
					> https://sgo.basis.com.br/browse/BASIS-53627                [FECHADO]
						> Baixar branch
						> Fazer Rebase (sincronizar com a master)
						> Push (subir branch atualizado com a master)
						> Criar MR  
						> Cherry-pick (para a versão 0.8) 
							> http://www.oabsp.org.br/sobre-oabsp/grandes-causas/a-comunista
							> http://www.caixa.gov.br/Paginas/home-caixa.aspx
							> http://www.tse.jus.br/eleicoes/eleicoes-2018/informacoes-sobre-as-eleicoes-2018
							> https://www.stm.jus.br/
							> http://portal.cfm.org.br/

					> CORRIGIR CODIGO JAVA (PARAMETRODAO)                         [PROCRASTINADO]
					> COLOCAR 'ALT' CORRETOS NOS BOTÕES (TOOLIP)                  [PROCRASTINADO]
					> O SISTEMA DEVE RECONHECER AS PALAVRAS DE                    [PROCRASTINADO]
					  DENTRO DO DOCUMENTO DOS AUTOS DIGITAIS                      
					> AO DESATIVAR O RYBENA VIA PARAMETRO O                       [PROCRASTINADO]
					  BOTAO JAVASCRIPT DEVE SER OMITIDO TAMBÉM
					> CORRIGIR DEFEITO: AO CLICAR DUAS VEZES NOS BOTOES           [PROCRASTINADO]
					  ELES DESAPARECEM DA TELA

			# [BASIS-54363] https://sgo.basis.com.br/browse/BASIS-54363          [PROCRASTINADO]
				> PROCESSO SEM NO DE TAREFA
					> DEVE IR PARA QUAL TAREFA ?
						> SEGUNDO O TAYNER DEVE SER MANDADO PARA A TAREFA 'AVALIAR DETERMINAÇÕES'

			# [TAYNER] PROBLEMAS NA MINUTA EM ELABORACAO                         [PROCRASTINADO]
				> EXECUTAR SCRIPT DE 'MINUTA EM ELABORACAO'

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341          [PROCRASTINADO]
			    > VERIFICAR PROBLEMA DE MINUTA EM ELABORACAO          
				> VERIFICAR ORIGEM DO PROBLEMA
				> CORRIGIR FETIVAMENTE O PROBLEMA

			# [BRUNO] 'SESSÃO CONTINUA'                                          [PROCRASTINADO]
				> (VIRTUAL) EXECUTA JOB ANTES DA DATA PREVISTA
					> CORRIGIR PROBLEMA
						> SERÁ COLOCADO EM UMA SPRINT

			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'.  		 [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA APRESENTAR ERRO PARA SER FECHADA     [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA SER INICIADA AUTOMÁTICAMENTE         [PROCRASTINADO]
					> SERÁ COLOCADO EM UMA SPRINT		

			# [QUINTIN]  											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                      [PROCRASTINADO]
				> MARCAR CONSULTAS PARA
					> OTORRINO
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS


		## 23/08/2018 - QUINTA

			# BASIS-52983 - https://sgo.basis.com.br/browse/BASIS-52983 		 [HOMOLOGAR]	
				> PRAZO PARA MANIFESTACAO APARECE. NAO DEVE APARECER. INVESTIGAR.
					> REALIZADO A CORREÇÃO VIA SCRIPT
						> DEVE-SE REALIZAR A IDENTIFICAÇÃO E CORREÇÃO DO ERRO    

			# [PC-1415] http://www.cnj.jus.br/jira/browse/PC-1415                [HOMOLOGAR]
				> ALTERAR MOVIMENTOS DA SESSÃO DE JULGAMENTO			
					> ALTERAR A DATA PARA 136 PROCESSOS REFERENTE A SESSAO
					  POIS FOI GERADO RETROATIVAMENTE.
					  > SERÁ COLOCADO EM UMA SPRINT

			# [PC-1414] - http://www.cnj.jus.br/jira/browse/PC-1414              [IMPLEMENTANDO]
				> IMPLEMENTAR CONTROLE DE VISIBILIDADE DO RIBENA
					> PJEVII-2664
					> https://sgo.basis.com.br/browse/BASIS-53625                [FECHADO]
					> https://sgo.basis.com.br/browse/BASIS-53626                [HOMOLOGAR]
					> https://sgo.basis.com.br/browse/BASIS-53627                [FECHADO]
						> Baixar branch
						> Fazer Rebase (sincronizar com a master)
						> Push (subir branch atualizado com a master)
						> Criar MR  
						> Cherry-pick (para a versão 0.8) 
							> http://www.oabsp.org.br/sobre-oabsp/grandes-causas/a-comunista
							> http://www.caixa.gov.br/Paginas/home-caixa.aspx
							> http://www.tse.jus.br/eleicoes/eleicoes-2018/informacoes-sobre-as-eleicoes-2018
							> https://www.stm.jus.br/
							> http://portal.cfm.org.br/

					> CORRIGIR CODIGO JAVA (PARAMETRODAO)                         [FECHADO]
					> COLOCAR 'ALT' CORRETOS NOS BOTÕES (TOOLIP)                  [FECHADO]
					> O SISTEMA DEVE RECONHECER AS PALAVRAS DE                    [IMPLEMENTANDO]
					  DENTRO DO DOCUMENTO DOS AUTOS DIGITAIS                      
					> AO DESATIVAR O RYBENA VIA PARAMETRO O                       [AGUARDANDO]
					  BOTAO JAVASCRIPT DEVE SER OMITIDO TAMBÉM
					> CORRIGIR DEFEITO: AO CLICAR DUAS VEZES NOS BOTOES           [AGUARDANDO]
					  ELES DESAPARECEM DA TELA
					 > NO BROWSER 'MOZILLA FIREFOX' OS ICONES APARECEM COM 
					   RENDERIZAÇÃO INADEQUADA  

			# [BASIS-54363] https://sgo.basis.com.br/browse/BASIS-54363           [IMPLEMENTANDO]
				> PROCESSO SEM NO DE TAREFA
					> DEVE IR PARA QUAL TAREFA ?
						> SEGUNDO O TAYNER DEVE SER MANDADO PARA A TAREFA 'AVALIAR DETERMINAÇÕES'

			# [TAYNER] PROBLEMAS NA MINUTA EM ELABORACAO                         [AGUARDANDO]
				> EXECUTAR SCRIPT DE 'MINUTA EM ELABORACAO'

			# [BRUNO] RELATORIO - ETIQUETAS                                      [AGUARDANDO]

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341          [AGUARDANDO]
			    > VERIFICAR PROBLEMA DE MINUTA EM ELABORACAO          
				> VERIFICAR ORIGEM DO PROBLEMA
				> CORRIGIR FETIVAMENTE O PROBLEMA

			# [BRUNO] 'SESSÃO CONTINUA'                                          [PROCRASTINADO]
				> (VIRTUAL) EXECUTA JOB ANTES DA DATA PREVISTA
					> CORRIGIR PROBLEMA
						> SERÁ COLOCADO EM UMA SPRINT

			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'.  		 [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA APRESENTAR ERRO PARA SER FECHADA     [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA SER INICIADA AUTOMÁTICAMENTE         [PROCRASTINADO]
					> SERÁ COLOCADO EM UMA SPRINT		

			# [QUINTIN]  											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                      [PROCRASTINADO]
				> MARCAR CONSULTAS PARA
					> OTORRINO
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS


		## 24/08/2018 - SEXTA

			# BASIS-52983 - https://sgo.basis.com.br/browse/BASIS-52983 		 [FECHADO]	
				> PRAZO PARA MANIFESTACAO APARECE. NAO DEVE APARECER. INVESTIGAR.
					> REALIZADO A CORREÇÃO VIA SCRIPT
						> DEVE-SE REALIZAR A IDENTIFICAÇÃO E CORREÇÃO DO ERRO    

			# [PC-1415] http://www.cnj.jus.br/jira/browse/PC-1415                [FECHADO]
				> ALTERAR MOVIMENTOS DA SESSÃO DE JULGAMENTO			
					> ALTERAR A DATA PARA 136 PROCESSOS REFERENTE A SESSAO
					  POIS FOI GERADO RETROATIVAMENTE.
					  > SERÁ COLOCADO EM UMA SPRINT

			# [PC-1414] - http://www.cnj.jus.br/jira/browse/PC-1414              [FECHADO]
				> IMPLEMENTAR CONTROLE DE VISIBILIDADE DO RIBENA
					> PJEVII-2664
					> https://sgo.basis.com.br/browse/BASIS-53625                [FECHADO]
					> https://sgo.basis.com.br/browse/BASIS-53626                [FECHADO]
					> https://sgo.basis.com.br/browse/BASIS-53627                [FECHADO]
						> Baixar branch
						> Fazer Rebase (sincronizar com a master)
						> Push (subir branch atualizado com a master)
						> Criar MR  
						> Cherry-pick (para a versão 0.8) 
							> http://www.oabsp.org.br/sobre-oabsp/grandes-causas/a-comunista
							> http://www.caixa.gov.br/Paginas/home-caixa.aspx
							> http://www.tse.jus.br/eleicoes/eleicoes-2018/informacoes-sobre-as-eleicoes-2018
							> https://www.stm.jus.br/
							> http://portal.cfm.org.br/

					> CORRIGIR CODIGO JAVA (PARAMETRODAO)                         [FECHADO]
					> COLOCAR 'ALT' CORRETOS NOS BOTÕES (TOOLIP)                  [FECHADO]
					> O SISTEMA DEVE RECONHECER AS PALAVRAS DE                    [AGUARDANDO]
					  DENTRO DO DOCUMENTO DOS AUTOS DIGITAIS                      
					> AO DESATIVAR O RYBENA VIA PARAMETRO O                       [AGUARDANDO]
					  BOTAO JAVASCRIPT DEVE SER OMITIDO TAMBÉM
					> CORRIGIR DEFEITO: AO CLICAR DUAS VEZES NOS BOTOES           [AGUARDANDO]
					  ELES DESAPARECEM DA TELA
					 > NO BROWSER 'MOZILLA FIREFOX' OS ICONES APARECEM COM 
					   RENDERIZAÇÃO INADEQUADA  

			# [BASIS-54363] https://sgo.basis.com.br/browse/BASIS-54363           [FECHADO]
				> PROCESSO SEM NÓ DE TAREFA
					> DEVE IR PARA QUAL TAREFA ?
						> SEGUNDO O TAYNER DEVE SER MANDADO PARA A TAREFA 'AVALIAR DETERMINAÇÕES'

			# [TAYNER] PROBLEMAS NA MINUTA EM ELABORACAO                         [AGUARDANDO]
				> EXECUTAR SCRIPT DE 'MINUTA EM ELABORACAO'

			# [BRUNO] RELATORIO - ETIQUETAS                                      [AGUARDANDO]

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341          [AGUARDANDO]
			    > VERIFICAR PROBLEMA DE MINUTA EM ELABORACAO          
				> VERIFICAR ORIGEM DO PROBLEMA
				> CORRIGIR FETIVAMENTE O PROBLEMA

			# [BRUNO] 'SESSÃO CONTINUA'                                          [PROCRASTINADO]
				> (VIRTUAL) EXECUTA JOB ANTES DA DATA PREVISTA
					> CORRIGIR PROBLEMA
						> SERÁ COLOCADO EM UMA SPRINT

			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'.  		 [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA APRESENTAR ERRO PARA SER FECHADA     [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA SER INICIADA AUTOMÁTICAMENTE         [PROCRASTINADO]
					> SERÁ COLOCADO EM UMA SPRINT		

			# [QUINTIN]  											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                      [PROCRASTINADO]
				> MARCAR CONSULTAS PARA
					> OTORRINO
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS


		## 27/08/2018 - SEGUNDA

			# [BRUNO] RELATORIO - ETIQUETAS                                          [PROCRASTINADO]

			# [BASIS-54363] https://sgo.basis.com.br/browse/BASIS-54363              [PROCRASTINADO]
				> PROCESSO SEM NÓ DE TAREFA
					> DEVE IR PARA QUAL TAREFA ?
						> SEGUNDO O TAYNER DEVE SER MANDADO PARA A TAREFA 'AVALIAR DETERMINAÇÕES'

			# BASIS-54737 - https://sgo.basis.com.br/browse/BASIS-54737              [PROCRASTINADO]
				> ALTERAR TITULO DE DOCUMENTO DE ACORDÃO

			# RYBENÁ - FECHAR DEMANDAS NO SGO E JIRA
				# [BASIS-53625] - https://sgo.basis.com.br/browse/BASIS-53625        [PROCRASTINADO]
				# [BASIS-53626] - https://sgo.basis.com.br/browse/BASIS-53626        [PROCRASTINADO]
				# [BASIS-53627  - https://sgo.basis.com.br/browse/BASIS-53627        [PROCRASTINADO]
				# [PC-1414] - http://www.cnj.jus.br/jira/browse/PC-1414              [PROCRASTINADO]
					> O SISTEMA DEVE RECONHECER AS PALAVRAS DE                       [PROCRASTINADO]
					  DENTRO DO DOCUMENTO DOS AUTOS DIGITAIS
					> DESABILITAR JAVASCRIPT DO BOTOES                               [PROCRASTINADO]			

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341              [PROCRASTINADO]
			    > VERIFICAR PROBLEMA DE MINUTA EM ELABORACAO          
				> VERIFICAR ORIGEM DO PROBLEMA
				> CORRIGIR FETIVAMENTE O PROBLEMA

			# [BRUNO] 'SESSÃO CONTINUA'                                              [PROCRASTINADO]
				> (VIRTUAL) EXECUTA JOB ANTES DA DATA PREVISTA
					> CORRIGIR PROBLEMA
						> SERÁ COLOCADO EM UMA SPRINT

			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'.  		    [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA APRESENTAR ERRO PARA SER FECHADA        [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA SER INICIADA AUTOMÁTICAMENTE            [PROCRASTINADO]		

			# [QUINTIN]  											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                                   [PROCRASTINADO]
				> MARCAR CONSULTAS PARA
					> OTORRINO
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS


		## 28/08/2018 - TERCA

			# [BASIS-54363] https://sgo.basis.com.br/browse/BASIS-54363              [PROCRASTINADO]
				> PROCESSO SEM NÓ DE TAREFA
					> DEVE IR PARA QUAL TAREFA ?
						> SEGUNDO O TAYNER DEVE SER MANDADO PARA A TAREFA 'AVALIAR DETERMINAÇÕES'

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341              [PROCRASTINADO]
			    > VERIFICAR PROBLEMA DE MINUTA EM ELABORACAO          
				> VERIFICAR ORIGEM DO PROBLEMA
				> CORRIGIR FETIVAMENTE O PROBLEMA

			# [BRUNO] 'SESSÃO CONTINUA'                                              [PROCRASTINADO]
				> (VIRTUAL) EXECUTA JOB ANTES DA DATA PREVISTA
					> CORRIGIR PROBLEMA
						> SERÁ COLOCADO EM UMA SPRINT

			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'.  		    [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA APRESENTAR ERRO PARA SER FECHADA        [PROCRASTINADO]
				> VERIFICAR SE A SESSAO IRA SER INICIADA AUTOMÁTICAMENTE            [PROCRASTINADO]		

			# [QUINTIN] 											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                                   [PROCRASTINADO]
				> MARCAR CONSULTAS PARA
					> OTORRINO                                                      [FECHADO]
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS


		## 29/08/2018 - QUARTA

			# [BASIS-54737] https://sgo.basis.com.br/browse/BASIS-54737              [PROCRASTINADO]

			# [BASIS-54363] https://sgo.basis.com.br/browse/BASIS-54363              [PROCRASTINADO]

			# PJEVII-1368 - http://www.cnj.jus.br/jira/browse/PJEVII-1368   	     [PROCRASTINADO]
			
			# PJEVII-1696 - http://www.cnj.jus.br/jira/browse/PJEVII-1696            [PROCRASTINADO]

			# [BASIS-54110] https://sgo.basis.com.br/browse/BASIS-54110              [PROCRASTINADO]
				> ERRO NO SISTEMA SOBRE INTIMAÇÕES SEM PRAZO (VIA SISTEMA)
					> 

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341              [PROCRASTINADO]
				> ERRO NO SISTEMA AO TRAMITAR PROCESSOS PARA A 
				  TAREFA 'MINUTAR DECISÃO'

			# [BRUNO] 'SESSÃO CONTINUA'                                              [PROCRASTINADO]

			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'   		     [PROCRASTINADO]

			# [QUINTIN]  											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                                    [PROCRASTINADO]
				> MARCAR CONSULTAS PARA
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS


		## 30/08/2018 - QUINTA

			# [BASIS-54737] https://sgo.basis.com.br/browse/BASIS-54737              [PROCRASTINADO]

			# [BASIS-54363] https://sgo.basis.com.br/browse/BASIS-54363              [PROCRASTINADO]

			# [PJEVII-1368] - http://www.cnj.jus.br/jira/browse/PJEVII-1368   	     [PROCRASTINADO]
			
			# [PJEVII-1696] - http://www.cnj.jus.br/jira/browse/PJEVII-1696          [PROCRASTINADO]

			# [BASIS-54110] https://sgo.basis.com.br/browse/BASIS-54110              [PROCRASTINADO]
				> ERRO NO SISTEMA SOBRE INTIMAÇÕES SEM PRAZO (VIA SISTEMA) 
					> origin/master
					> 2.0.0.5_cnj
					> 2.0.0.7_cnj
						> ERROR DE ASSINADOR DIGITAL
						> ERRO NO STORAGE
						> ERRO COM PAINEL (DIRETOR DE SECRETARIA NAO RENDERIZA)
						> /home/desenvolvimento/Desenvolvimento/alef/alef_WORKSPACE/6_PJE_EVOLUTIVA        -- ESTAVEL

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341              [PROCRASTINADO]
				> ERRO NO SISTEMA AO TRAMITAR PROCESSOS PARA A 
				  TAREFA 'MINUTAR DECISÃO'

			# [BRUNO] 'SESSÃO CONTINUA'                                              [PROCRASTINADO]

			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'   		     [PROCRASTINADO]

			# [TAREFAS PESSOAIS]  											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                                    [PROCRASTINADO]
				> MARCAR CONSULTAS PARA                                              [PROCRASTINADO]
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS
				> SOLICITAR DEPOSITO DE VALE TRANSPORTE 

				
		## 31/08/2018 - SEXTA

			# [BASIS-54737] https://sgo.basis.com.br/browse/BASIS-54737              [PROCRASTINADO]

			# [BASIS-54737] https://sgo.basis.com.br/browse/BASIS-54363              [PROCRASTINADO]

			# [BASIS-54363] GERAR CHECKLIST DEMANDAS JIRA		                     [PROCRASTINADO]

			# [PJEVII-1368] - http://www.cnj.jus.br/jira/browse/PJEVII-1368   	     [PROCRASTINADO]
			
			# [PJEVII-1696] - http://www.cnj.jus.br/jira/browse/PJEVII-1696          [GERAR EVIDENCIAS]

			# [BASIS-54110] https://sgo.basis.com.br/browse/BASIS-54110              [PROCRASTINADO]
				> ERRO NO SISTEMA SOBRE INTIMAÇÕES SEM PRAZO (VIA SISTEMA) 
					> origin/master
					> 2.0.0.5_cnj
					> 2.0.0.7_cnj
						> ERROR DE ASSINADOR DIGITAL
						> ERRO NO STORAGE
						> ERRO COM PAINEL (DIRETOR DE SECRETARIA NAO RENDERIZA)
						> /home/desenvolvimento/Desenvolvimento/alef/alef_WORKSPACE/6_PJE_EVOLUTIVA        -- ESTAVEL

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341              [PROCRASTINADO]
				> ERRO NO SISTEMA AO TRAMITAR PROCESSOS PARA A 
				  TAREFA 'MINUTAR DECISÃO'

			# [BRUNO] 'SESSÃO CONTINUA'                                              [PROCRASTINADO]

			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'   		     [PROCRASTINADO]

			# [TAREFAS PESSOAIS]  											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                                    [PROCRASTINADO]
				> MARCAR CONSULTAS PARA                                              [PROCRASTINADO]
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS
				> SOLICITAR DEPOSITO DE VALE TRANSPORTE


		## 04/09/2018 - TERCA

			# [BASIS-54737] https://sgo.basis.com.br/browse/BASIS-54737              [FECHADO]

			# [BASIS-54737] https://sgo.basis.com.br/browse/BASIS-54363              [FECHADO]

			# [PC-1419] http://www.cnj.jus.br/jira/browse/PC-1419                    [FECHADO]

			# [PC-1420] http://www.cnj.jus.br/jira/browse/PC-1420                    [FECHADO]

			# [PC-1422] http://www.cnj.jus.br/jira/browse/PC-1422                    [FECHADO]
  
			# [BASIS-55536] https://sgo.basis.com.br/browse/BASIS-55536              [FECHADO]

			# [BRUNO]       GERAR CHECKLIST DEMANDAS JIRA		                     [FECHADO]

			# [PJEVII-1368] - http://www.cnj.jus.br/jira/browse/PJEVII-1368   	     [GERAR EVIDENCIAS]
			
			# [PJEVII-1696] - http://www.cnj.jus.br/jira/browse/PJEVII-1696          [GERAR EVIDENCIAS]

			# [BASIS-54110] https://sgo.basis.com.br/browse/BASIS-54110              [EXECUÇÃO]
				> ERRO NO SISTEMA SOBRE INTIMAÇÕES SEM PRAZO (VIA SISTEMA) 
					> origin/master
					> 2.0.0.5_cnj
					> 2.0.0.7_cnj
						> ERROR DE ASSINADOR DIGITAL
						> ERRO NO STORAGE
						> ERRO COM PAINEL (DIRETOR DE SECRETARIA NAO RENDERIZA)
						> /home/desenvolvimento/Desenvolvimento/alef/alef_WORKSPACE/6_PJE_EVOLUTIVA        -- ESTAVEL

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341              [PROCRASTINADO]
				> ERRO NO SISTEMA AO TRAMITAR PROCESSOS PARA A 
				  TAREFA 'MINUTAR DECISÃO'

			# [BRUNO] 'SESSÃO CONTINUA'                                              [PROCRASTINADO]

			# [BRUNO]     - TESTAR 'FECHAR PAUTA' NA BRANCH '2.0.0.8'   		     [PROCRASTINADO]

			# [TAREFAS PESSOAIS]  											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                                    [PROCRASTINADO]
				> MARCAR CONSULTAS PARA                                              [PROCRASTINADO]
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS
				> SOLICITAR DEPOSITO DE VALE TRANSPORTE


		## 05/09/2018 - QUARTA

			# [PJEVII-1368] http://www.cnj.jus.br/jira/browse/PJEVII-1368   	     [PROCRASTINADO]
			
			# [PJEVII-1696] http://www.cnj.jus.br/jira/browse/PJEVII-1696            [PROCRASTINADO]

			# [BASIS-54110] https://sgo.basis.com.br/browse/BASIS-54110              [PROCRASTINADO]

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341              [PROCRASTINADO]
 
			# [BASIS-55971] https://sgo.basis.com.br/browse/BASIS-55971              [PROCRASTINADO]

			# [BASIS-55970] https://sgo.basis.com.br/browse/BASIS-55970 			 [PROCRASTINADO]

			# [BASIS-55967] https://sgo.basis.com.br/browse/BASIS-55967              [PROCRASTINADO]
 
 			# [BASIS-55328] https://sgo.basis.com.br/browse/BASIS-55328              [PROCRASTINADO]

			# [BASIS-55327] https://sgo.basis.com.br/browse/BASIS-55327				 [PROCRASTINADO]	
   
			# [TAREFAS PESSOAIS]  											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                                    [PROCRASTINADO]
				> MARCAR CONSULTAS PARA                                              [PROCRASTINADO]
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS



		## 06/09/2018 - QUINTA

			# [BASIS-55967] https://sgo.basis.com.br/browse/BASIS-55967              [HOMOLOGAR]
				> /Desenvolvimento/Vanadio/vanadio_REPOSITORY/vanadio_GIT_MASTER/pje
					> EXECUTAR COMANDO "GIT FETCH ORGIN MASTER" DEPOIS DE HOMOLOGADO

			# [BASIS-55971] https://sgo.basis.com.br/browse/BASIS-55971              [HOMOLOGAR]

			# [BASIS-55970] https://sgo.basis.com.br/browse/BASIS-55970 			 [HOMOLOGAR]

			# [PJEVII-1368] http://www.cnj.jus.br/jira/browse/PJEVII-1368   	     [GERAR EVIDENCIAS]
				# [BASIS-55328] https://sgo.basis.com.br/browse/BASIS-55328              [AGUARDANDO]
			
			# [PJEVII-1696] http://www.cnj.jus.br/jira/browse/PJEVII-1696            [GERAR EVIDENCIAS]
				# [BASIS-55327] https://sgo.basis.com.br/browse/BASIS-55327				 [AGUARDANDO]

			# [BASIS-54110] https://sgo.basis.com.br/browse/BASIS-54110              [PAUSADO]

			# [BASIS-54341] https://sgo.basis.com.br/browse/BASIS-54341              [AGUARDANDO]			

			# [TAYNER] EXCLUIR DOCUMENTOS DE UM PROCESSO 		 			         [AGUARDANDO]
   
			# [TAREFAS PESSOAIS]  											             

				> SUBIR WILDFLY EM DOIS AMBIENTES                                    [PROCRASTINADO]
				> MARCAR CONSULTAS PARA                                              [PROCRASTINADO]
					> DERMATOLOGISTA
					> ODONTOLOGIA (RENATA)
						> MANDAR LISTA DE CLINICAS
				   
				   
	## 02/10/2018 - TERCA [RETORNO DAS FERIAS]

			# [BASIS-58334] https://sgo.basis.com.br/browse/BASIS-58334									   [VERIFICANDO]
			# [BASIS-59276] https://sgo.basis.com.br/browse/BASIS-59276									   [FECHADO]
			# [BASIS-59059] https://sgo.basis.com.br/browse/BASIS-59059									   [FECHADO]		   

---------------------------------------------------------------------
# PROCEDIMENTOS MYSQL
---------------------------------------------------------------------

	# ACESSAR BANCO DE DADOS POR COMMAND LINE
		$ mysql -u root -p

---------------------------------------------------------------------
# TAREFAS DO SISTEMA PJE
---------------------------------------------------------------------

	# TAREFAS DA SECRETARIA

		$ 

---------------------------------------------------------------------
# COMANDOS GIT
---------------------------------------------------------------------

	# RENOMEAR UMA DETERMINADA BRANCH
	
	# VERIFICAR COMMITS E BRANCHES

		-- DELETAR BRANCH

			-- LOCAL
				$ git branch -D <nome do branch>
				
			-- REMOTO
				$ git push <nome do origin> <nome do branch> --delete

		-- ALTERAR MENSAGEM DE COMMITS
			$ git log
			$ git rebase -i <HASH_LOG_COMMIT>
			$ AO ABRIR O EDITOR DEVE-SE COLOCAR A PALAVRA 'reword' A FRENTE DO COMMIT A SER ALTERADO
			$ SERA ABERTO UM NOVO ARQUIVO. ALTERAR O CONTEUDO DO COMMIT. FECHAR EDITOR ('CTRL + O' && 'CTRL + X')

		-- VERIFICAR ARQUIVOS QUE ESTAO SENDO CONTROLADOS
			$ git ls-files

		-- OBTER INFORMACOES DO ARQUIVO SOBRE ALTERACOES
			$ git whatchanged
			$ git whatchanged -p    // PEGA AS ALTERACOES DOS ARQUIVOS

		-- VERIFICAR ALTERACOES EM UM DETERMINADO ARQUIVO
			$ git diff <ARQUIVO>

		-- VERIFICAR HISTORICO DE COMMITS (LINHA A LINHA E POR USUARIOS)
			$ git blame <ARQUIVO>

		- VERIFICAR HISTORICO DE COMMITS
			$ git log  

		- VERIFICAR HISTORICO DE COMMITS (UNICA LINHA)
			$ git log --oneline

		- VERIFICAR HISTORICO DE COMMITS (HASH COMPLETO UNICA LINHA)
			$ git log --pretty=oneline

		- MOSTRA ESTATISTICAS DE ARQUIVOS COMMITADOS
			$ git log --stat

		- VERIFICAR DIFERENCAS DE ARQUIVOS ALTERADOS
			$ git log -p -2
				   
	# CRIAR NOVA BRANCH
		$ git checkout -b <NOME_BRANCH>
				   
	# CONFIGURAR IDENTIFICACAO GIT

		$ git config --global user.email "jose.quintino@basis.com.br"
		$ git config --global user.name "José Quintino da Silva Júnior"

		$ git config --global user.email "repository.developmet@gmail.com"
		$ git config --global user.name "Development Repository"

		$ git config --global user.email "repository.production@gmail.com"
		$ git config --global user.name "Production Repository"
        
        $ git config --global user.email "repository.desenvolvimento@gmail.com"
		$ git config --global user.name "Repository Desenvolvimento"

	# ENDERECO PJE CNJ 

		## GIT 1.7
			$ https://git.cnj.jus.br/pje/pje

		## GIT 2.0
			$ https://git.cnj.jus.br/pje-2/pje2

	# CRIAR UMA BRANCH LOCAL A PARTIR DA MASTER
		$ git checkout master -b PLVD-0001

	# RENOMEAR UM BRANCH
		$ git branch -m PLVD-0001 development

	# CRIAR UMA BRANCH LOCAL A PARTIR DE UMA TAG
		$ git pull											// ATUALIZAR UMA BRANCH DA MASTER
		$ git checkout tags/2.0.0.8 -b 2.0.0.8_cnj 			// CRIAR BRANCH LOCAL COM REFERENCIA A MASTER

	# CRIAR CHAVE SSH PARA O GIT (Fonte: https://gist.github.com/brunorozendo/0b5d26a3043828fe7568c36e6182b9be)
		$ ssh-keygen -t rsa -b 4096 -C "jose.quintino@basis.com.br"
		$ ssh-add ~/.ssh/id_rsa
		$ cat ~/.ssh/id_rsa.pub | xclip -sel clip

	# REALIZAR CHERRY-PICK

		-- ACESSAR A BRANCH DE ORIGEM DO COMMIT. ONDE GUARDA A BRANCH.
			> git checkout 2.0.0.5_cnj

		-- ACESSAR A BRANCH DE DESTINO PARA FAZER CHERRY-PICK COM O IDENTIFICADOR DA BRANCH.
			> git checkout 2.0.0.7_cnj 
			> git cherry-pick d16083759a92359ad7652885f673e6e281db1242 // LOG DO COMMIT A SER INSERIDO
			> git cherry-pick --continue // CONTINUAR O PROCESSO DE CHERRY-PICK

		--COMMIT
			> git push origin 2.0.0.7_cnj

	# REALIZAR SQUASH (TRANSFORMAR VÁRIOS COMMIT EM UM UNICO - REESCREVENDO O HISTORICO)

		// ACESSAR BRANCH MASTER 
		// SINCRONIZAR A BRANCH LOCAL E A BRANCH DO REPOSITORY
			$ git fetch origin 
		// FAZER REBASE
			$ git rebase -i master
		// 
		$ git 
				   
	# RESETAR REPOSITORIO LOCAL IGUAL A MASTER DA BRANCH				   
		$ git reset --hard origin/2.0.0.7_cnj

	# COMMITAR NO REPOSITORIO GITHUB		
		$ git fetch
		$ git pull
		$ git status
		$ rm .gitignore
		$ git add *
		$ git log
		$ git commit -m '<MENSAGEM_COMMIT>'
		$ git push 

---------------------------------------------------------------------
# COMANDOS ECLIPSE
---------------------------------------------------------------------

	# DEIXAR IDE ECLIPSE MAIS RAPIDA

		-- ERRO DE JPA 'Eclipse JPA Project Change Event Handler (waiting)'
			$ https://stackoverflow.com/questions/19649847/eclipse-jpa-project-change-event-handler-waiting

---------------------------------------------------------------------
# PROCEDIMENTOS MAVEN
---------------------------------------------------------------------

	# EXECUTAR VIA CONSOLE

		-- MIGRATE
			$ mvn flyway:migrate -P pje-descanso -X                        -- VIA CONSOLE
			$ flyway:migrate -P pje-descanso							   -- VIA ECLIPSE 

		-- CLEAN / INSTALL (via eclipse)
			$ MVN_CLEAN_INSTALL - clean install -DskipTests - 
			$ clean install -DskipTests -X
			$ clean install -DskipTests -U 								    -- FAZ UPDATE

---------------------------------------------------------------------
# CONFIGURAÇÃO DE AMBIENTE DE DESENVOLVIMENTO CNJ PJE 
---------------------------------------------------------------------

	## DUAS INSTÂNCIAS DO WILDFLY

		# ALTERAR OS ARQUIVOS
			# /home/desenvolvimento/Desenvolvimento/01_DESENVOLVIMENTO/alef_GIT/1_PJE_2.0.0.5_cnj/pje/pje-web/src/main/resources/integracao.properties 
			# /home/desenvolvimento/Desenvolvimento/01_DESENVOLVIMENTO/alef_GIT/1_PJE_2.0.0.5_cnj/pje/pje-web/src/main/java/br/jus/cnj/pje/integracao/pje2/RestFilter.java
			# NOT 'STANDALONE-FULL.XML' DEVE-SE ALTERAR O TREXO '<socket-binding name="http" port="${jboss.http.port:8081}"/>' PARA O NUMERO DA PORTA DESEJADA

	## ERRO PJE OFFICE. ERRO AO TENTAR ASSINAR DOCUMENTO.
	
		# USAR 'FIREFOX' PARA O PJE
			> INSTALAR JDK DA ORACLE
			> COPIAR ARQUIVOS DO FIREFOX PARA O PASTA DA JDK 
				> 

	## CONFIGURAÇÕES DO WILDFLY
		> PROGRAM ARGUMENTS

			> -mp "/home/desenvolvimento/Desenvolvimento/ZAYN/z_SERVER/z_WILDFLY/modules" -jaxpmodule javax.xml.jaxp-provider -jaxpmodule javax.xml.jaxp-provider org.jboss.as.standalone -b 0.0.0.0 --server-config=standalone-full.xml -Djboss.server.base.dir=/home/desenvolvimento/Desenvolvimento/ZAYN/z_SERVER/z_WILDFLY/standalone

		> VM ARGUMENTS

			> "-Dprogram.name=JBossTools: WildFly 9.x" -server -Xms1024m -Xmx1024m -XX:MaxPermSize=256m -Dorg.jboss.resolver.warning=true -Djava.net.preferIPv4Stack=true -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Djboss.modules.system.pkgs=org.jboss.byteman -Djava.awt.headless=true "-Dorg.jboss.boot.log.file=/home/desenvolvimento/Desenvolvimento/ZAYN/z_SERVER/z_WILDFLY/standalone/log/boot.log" "-Dlogging.configuration=file:/home/desenvolvimento/Desenvolvimento/ZAYN/z_SERVER/z_WILDFLY/standalone/configuration/logging.properties" "-Djboss.home.dir=/home/desenvolvimento/Desenvolvimento/ZAYN/z_SERVER/z_WILDFLY" -Dorg.jboss.logmanager.nocolor=true -Djboss.bind.address.management=0.0.0.0 -Dfile.encoding=UTF8 -Dpje.producao=false -noverify

---------------------------------------------------------------------
# COMPUTAÇÃO
---------------------------------------------------------------------
    
    # TREINAMENTOS
        
      $ ANGULAR + SPRING BOOT
        - https://www.youtube.com/watch?v=dg0aZbP8NAU&list=PLKvsMn7xWutbSELeX5j8CXF2Lxd2cj19J
            
      $ ANGULARJS + REST
        - https://www.youtube.com/watch?v=mK-4aB5dfrc&list=PL1NdiP2jsLnuEqNkOF7-ISTciRrKd51Hv
                
      $ ANGULARJS + JAVA 8
        - https://www.youtube.com/watch?v=pnlkVVfwwC0&list=PLhN3osRme7BVTwLWsVThCkIcW0fB51eAU
                
      $ ANGULARJS + STARTER
        - https://www.youtube.com/watch?v=_y7rKxqPoyg&list=PLQCmSnNFVYnTD5p2fR4EXmtlR6jQJMbPb
        
      $ ANGULAR 2 - STARTER
        - https://www.youtube.com/watch?v=tPOMG0D57S0&list=PLGxZ4Rq3BOBoSRcKWEdQACbUCNWLczg2G
        
      $ TYPESCRIPT
        - https://www.youtube.com/watch?v=67ki0t_VWc0&list=PL62G310vn6nGg5OzjxE8FbYDzCs_UqrUs
         
	# LINKS
		
        ## JAVA
			$ https://stackoverflow.com/questions/19649847/eclipse-jpa-project-change-event-handler-waiting

		## CNJ
			# VANADIO INTERNA                                        
				$ http://vanadiod04.cnj.jus.br:8080/pjecnj/login.seam?loginComCertificado=true

			# VANADIO EXTERNA                                        
				$ http://wwwh.cnj.jus.br/pjecnj/login.seam?loginComCertificado=true

			# http://172.20.18.66:8080/
				> MAQUINA ROGER
					> wildfly (CONSOLE)
						> admin
						> adm-123
					> basis (DA MAQUINA)
						> admin

			# http://172.20.18.73:8081/pje-web
				> MAQUINA BRUNO ROZENDO

		## CONCURSO PÚBLILCO
			$ https://drive.google.com/drive/folders/0B5McIHNcYFWZWWotdllZV1F5Nmc
			$ https://drive.google.com/drive/folders/0B1j6T9nggVLbS3Y2UXQyUWxOUmc
			$ https://drive.google.com/drive/folders/0B7DZdGrd5LrRcWNKZkp5WE5pRVU
			$ https://drive.google.com/drive/folders/0B7uJkiX2MVPgTmFVcGU5SUd5TWM
			$ https://drive.google.com/drive/folders/0B1EE5kl4smCybkZkNGhwZkhhU3M
			$ https://drive.google.com/drive/folders/0B1EE5kl4smCyWWxHZXJHalprRHM
			$ https://drive.google.com/drive/folders/0ByWY5LWjDpLMTDU0and3X2k1c1k
			$ https://mega.nz/#F!Ox1TlZrb!_ydgNOiX0LabrAyissrnzQ
			$ https://drive.google.com/drive/folders/0BwQVtcaBt81tYVNYLWtuTllTNmc
			$ https://drive.google.com/drive/folders/0B7URW_vbvwtHNHk3MkNfdnNrNU0
					
---------------------------------------------------------------------
# JUDAISMO
---------------------------------------------------------------------
	
	# TERMOS 
		$ Rodef							- Perseguidor Mortal. Citado por Rambam (aplicado em caso de Aborto)
		$ Kolel							- Designa uma Reunião de estudos com pessoas ao redor de uma mesa que discutem temas relacionados sobre halachah
		$ Halachah						- Originária de verbo "chalach" que significa 'caminhar'. Está relacionado a extração (drashah ou midrashim) de regras de interpretação da Torah e aplicação da Lei	perfeitamente das Mitzvot (baseado em Tehilim 119:04 que diz: "Tu ordenaste os teus mandamentos, para que diligentemente os observássemos"). Estudos dos compédios interpretativo (literatura rabinica) para que a cada geração houvesse uma interpretação de forma mais elevada.
		$ Midrash 						- Extração. Possuem dois tipos de Misdrash, a saber, Misdrash Agadah (parabolas) e Misdrash Halachah (extrações legislativas. Determinações das Mitzvot)
		$ Elul 							- Mês do calendário judaíco. 
		$ Sherinah HaShem				- Presença de D-us no mundo (Olam Hazeh)
		$ Hamakom 						- "O lugar". O Misdrash Agadah se refere a D-us como "quele que é o lugar no mundo, mas o mundo não é o seu lugar"	
		$ Melech Hamashiach				- "Rei Mashiach"
		$ Haverah						- Transgreção.
		$ Aviv 							- Mês da Primavera. Representa o período. Conhecido como Nissan.
		$ Nissan						- Inicio do ano religioso.
		$ Tishirei						- Sétimo mês do calendário religioso é o primeiro mês do calendário civil. E o sétimo mês do calendário civil e o primeiro mês do calendário religioso.


---------------------------------------------------------------------
# CORRECAO DE DEMANDAS
---------------------------------------------------------------------

#### [http://www.cnj.jus.br/jira/browse/PC-1415]

	### [PC-1415] SCRIPT DE ANALISE

		SELECT * FROM TB_PROCESSO WHERE ID_PROCESSO = 967;

		-- ### REORDENAR AS MOVIMENTACOES PARA OS '136' PROCESSOS REFERENTE A SESSAO '491 - 49ª Sessão Extraordinária' DO DIA '14/08/2018'
		SELECT * FROM TB_SESSAO WHERE DS_APELIDO ILIKE '%49ª Sessão Extraordinária%';

		-- LOCALIZAR TODO OS PROCESSOS DA SESSAO
		SELECT COUNT(*) FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491;

		SELECT * FROM TB_PROCESSO WHERE ID_PROCESSO = 90781;

		SELECT * FROM TB_PROCESSO WHERE NR_PROCESSO ILIKE '0000676-16.2016.2.00.0000';

		SELECT * FROM TB_PROCESSO_EVENTO WHERE ID_PROCESSO = 90781 ORDER BY DT_ATUALIZACAO DESC;

		SELECT * FROM TB_PROCESSO_EVENTO WHERE (TO_CHAR(DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18') AND ID_USUARIO = 7870;

		SELECT * FROM TB_PROCESSO_EVENTO WHERE (TO_CHAR(DT_ATUALIZACAO::DATE, 'YYYY-MM-DD HH24:MI:SS') = '2018-08-16 13:18:30');

		SELECT * FROM TB_PROCESSO_EVENTO WHERE ID_PROCESSO = 90781 AND DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30' AND ID_EVENTO = 1000000006;

		SELECT * FROM TB_PROCESSO_EVENTO WHERE DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30';

		SELECT * FROM CORE.TB_EVENTO WHERE ID_EVENTO = 1000000006 ;
		SELECT * FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491 ORDER BY TP_SITUACAO_JULGAMENTO;
		SELECT * FROM TB_PROCESSO_EVENTO WHERE ID_PROCESSO = 9452 AND DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30';
		SELECT * FROM TB_PROCESSO_EVENTO WHERE ID_PROCESSO = 72150 AND DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30';
		SELECT * FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491;

		SELECT TP_SITUACAO_JULGAMENTO FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491 AND ID_PROCESSO_TRF IN ( 90781, 77964, 103964, 95036, 97151, 85204, 81247, 90539, 93522, 102311, 98598, 92008, 101724, 100412, 75927, 101042, 81458, 81923, 83681, 85818, 86079, 87531, 87460, 102394, 88644, 89897, 96537, 92193, 94807, 99510, 95873, 94385, 99343, 99059, 99108, 98621, 86926, 93584, 92561, 105930, 3477, 98945, 88271, 54352, 60953, 70514, 95882, 96871, 66649, 80937, 56046, 98302, 72325, 58748, 68632, 68825, 66490, 64602, 80452, 67634, 99185, 75876, 72150, 57651, 86385, 52266, 50951, 74100, 77040, 97617, 99090, 54513, 81338, 91616, 9452, 76181, 83057, 75404, 79463, 88908, 83036, 83094, 79279, 76547, 49695, 75025, 67186, 70901, 88696, 67056, 618, 100564, 83143, 9137, 84557, 2397, 78105, 9738, 75414, 82972, 80267, 75402, 80447, 97173, 87333, 82128, 99488, 88043, 60475, 79249, 98193, 80685, 43281, 81276, 74610, 78577, 67184, 70528, 99558, 96259, 99490, 94680, 98096, 70638, 92980, 63939, 52632, 70525, 84918, 83527, 95949, 89929, 97287, 93704, 77682, 79538 ) ORDER BY TP_SITUACAO_JULGAMENTO;

		SELECT COUNT(*) FROM CLIENT.TB_PROCESSO_TRF WHERE ID_PROCESSO_TRF IN (90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927,
							101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510,
							95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
							95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
							72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
							79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
							84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
							98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
							52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);
						
						
						
		SELECT * FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491 AND ID_PROCESSO_TRF = 9452;				
						
		SELECT * FROM TB_PROCESSO_EVENTO WHERE ID_PROCESSO = 9452 AND (TO_TIMESTAMP(DT_ATUALIZACAO::DATE, 'YYYY-MM-DD HH24:MI:SS'));
		AND DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30';				
						
						
						
		--SELECT  COUNT(*)
		--SELECT  C.ID_EVENTO, A.ID_PROCESSO_TRF
		SELECT A.ID_SESSAO, A.ID_PROCESSO_TRF, C.DT_ATUALIZACAO, C.ID_EVENTO
		FROM TB_SESSAO_PAUTA_PROC_TRF A
		INNER JOIN CLIENT.TB_PROCESSO_TRF B
		ON A.ID_PROCESSO_TRF = B.ID_PROCESSO_TRF
		INNER JOIN CORE.TB_PROCESSO_EVENTO C
		ON C.ID_PROCESSO = B.ID_PROCESSO_TRF
		WHERE A.ID_SESSAO = 491
		AND C.ID_EVENTO IN(1000000006,1000000007,1000000008,1000000000)
		AND C.DT_ATUALIZACAO::DATE = '2018-08-16 13:18'
		AND A.ID_PROCESSO_TRF IN(90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927,
							101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510,
							95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
							95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
							72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
							79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
							84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
							98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
							52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);
						
						
						
		SELECT * FROM CORE.TB_EVENTO WHERE DS_EVENTO ILIKE '%Deliberado em sessão%';
		SELECT * FROM CORE.TB_EVENTO WHERE ID_EVENTO IN(1000000000, 1000000006, 1000000007, 1000000008);

		SELECT COUNT(*) 
		FROM TB_SESSAO_PAUTA_PROC_TRF A
		INNER JOIN CLIENT.TB_PROCESSO_TRF B
		ON A.ID_PROCESSO_TRF = B.ID_PROCESSO_TRF
		INNER JOIN CORE.TB_PROCESSO_EVENTO C
		ON C.ID_PROCESSO = B.ID_PROCESSO_TRF
		WHERE A.ID_SESSAO = 491
		AND (C.ID_EVENTO = 1000000006)
		AND C.DT_ATUALIZACAO::DATE = '2018-08-16 13:18'
		AND A.ID_PROCESSO_TRF IN(90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927,
							101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510,
							95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
							95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
							72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
							79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
							84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
							98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
							52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);


		-- PROCESSOS PAUTADOS NA SESSAO '491 - 49ª Sessão Extraordinária' DO DIA '14/08/2018'
		SELECT COUNT( ID_PROCESSO_TRF )
		FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF
		WHERE ID_SESSAO = 491;

		SELECT * FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491;


		SELECT PROCESSO_EVENTO_.ID_PROCESSO
		FROM TB_PROCESSO_EVENTO PROCESSO_EVENTO_
		WHERE ID_PROCESSO IN (
			SELECT ID_PROCESSO_TRF TB_PROCESSO_TRF
			FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF
			WHERE ID_SESSAO = 491
			AND (TO_CHAR(DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18')
		);

		-- RECUPERAR EVENTOS DA SESSAO PELA DATA E HORA '2018-08-16 13:18:30'
		SELECT *
		FROM TB_PROCESSO A
		INNER JOIN CORE.TB_PROCESSO_EVENTO B
		ON A.ID_PR	AND ID_PROCESSO IN( 90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927
								101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510
								95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
								95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
								72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
								79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
								84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
								98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
								52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);
		COMMIT TRANSACTION ;

		SELECT * FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491 AND ID_PROCESSO_TRF = 72150;OCESSO = B.ID_PROCESSO
		INNER JOIN TB_SESSAO_PAUTA_PROC_TRF C 
		ON C.ID_PROCESSO_TRF = B.ID_PROCESSO
		WHERE C.ID_SESSAO = 491
		AND B.DT_ATUALIZACAO::DATE = '2018-08-16 13:18'
		AND A.id_processo IN (90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927,
							101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510,
							95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
							95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
							72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
							79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
							84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
							98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
							52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);

		--SELECT COUNT(*) 
		SELECT *
		FROM TB_PROCESSO_EVENTO
		WHERE DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30'
		AND ID_PROCESSO IN( 90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927,
							101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510,
							95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
							95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
							72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
							79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
							84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
							98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
							52632,70525,84918,83527,95949,89929,97287,93704,77682,79538) ORDER BY ID_PROCESSO;

		SELECT * FROM TB_PROCESSO_EVENTO WHERE (TO_CHAR(DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18') AND ID_USUARIO = 7870;				
						
		-- ALTERA A MOVIMENTACAO DOS '136' PROCESSOS REFENTES A '491 - 49ª Sessão Extraordinária'
		BEGIN TRANSACTION ;
			--UPDATE TB_PROCESSO_EVENTO
			SET (TO_CHAR(DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18')
			WHERE ID_SESSAO = 491
			AND ID_USUARIO = 7870
			AND ID_PROCESSO IN( 90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927
								101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510
								95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
								95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
								72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
								79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
								84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
								98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
								52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);
		COMMIT TRANSACTION ;

		SELECT * FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491 AND ID_PROCESSO_TRF = 72150;

		-- VERIFICAR QUANTIDADES DOS TIPOS POSSIVEIS 'Deliberado em sessão - julgado', 'Deliberado em sessão - adiado'
		-- OBJETIVO: COLOCAR TODAS AS MOVIMENTAÇÕES DOS PROCESSOS DA SESSAO PARA O DIA '2018-08-16 00:00:00'

		SELECT * FROM TB_PROCESSO_EVENTO WHERE DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30';

		UPDATE core.tb_processo_evento
		SET id_processo=98598, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:44.837', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192703;
		UPDATE core.tb_processo_evento
		SET id_processo=101724, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:45.019', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192704;
		UPDATE core.tb_processo_evento
		SET id_processo=100412, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:45.177', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192705;
		UPDATE core.tb_processo_evento
		SET id_processo=103964, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:45.346', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192706;
		UPDATE core.tb_processo_evento
		SET id_processo=75927, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:45.530', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192707;
		UPDATE core.tb_processo_evento
		SET id_processo=95036, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:45.723', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192708;
		UPDATE core.tb_processo_evento
		SET id_processo=81247, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:45.860', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192709;
		UPDATE core.tb_processo_evento
		SET id_processo=85204, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:46.018', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192710;
		UPDATE core.tb_processo_evento
		SET id_processo=90539, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:46.148', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192711;
		UPDATE core.tb_processo_evento
		SET id_processo=93522, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:46.260', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192712;
		UPDATE core.tb_processo_evento
		SET id_processo=102394, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:46.368', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192713;
		UPDATE core.tb_processo_evento
		SET id_processo=102311, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:46.500', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192714;
		UPDATE core.tb_processo_evento
		SET id_processo=92008, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:46.644', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192715;
		UPDATE core.tb_processo_evento
		SET id_processo=101042, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:46.813', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192716;
		UPDATE core.tb_processo_evento
		SET id_processo=81458, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:47.024', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192717;
		UPDATE core.tb_processo_evento
		SET id_processo=81923, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:47.197', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192718;
		UPDATE core.tb_processo_evento
		SET id_processo=83681, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:47.471', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192719;
		UPDATE core.tb_processo_evento
		SET id_processo=85818, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:47.630', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192720;
		UPDATE core.tb_processo_evento
		SET id_processo=86079, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:48.031', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192721;
		UPDATE core.tb_processo_evento
		SET id_processo=86926, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:48.223', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192722;
		UPDATE core.tb_processo_evento
		SET id_processo=87460, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:48.400', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192723;
		UPDATE core.tb_processo_evento
		SET id_processo=87531, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:48.518', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192724;
		UPDATE core.tb_processo_evento
		SET id_processo=88644, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:48.627', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192725;
		UPDATE core.tb_processo_evento
		SET id_processo=89897, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:48.745', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192726;
		UPDATE core.tb_processo_evento
		SET id_processo=92193, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:48.919', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192727;
		UPDATE core.tb_processo_evento
		SET id_processo=93584, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:49.040', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192728;
		UPDATE core.tb_processo_evento
		SET id_processo=94807, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:49.144', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192729;
		UPDATE core.tb_processo_evento
		SET id_processo=98621, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:49.244', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192730;
		UPDATE core.tb_processo_evento
		SET id_processo=99510, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:49.481', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192731;
		UPDATE core.tb_processo_evento
		SET id_processo=92561, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:29.748', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192594;
		UPDATE core.tb_processo_evento
		SET id_processo=105930, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:29.866', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192595;
		UPDATE core.tb_processo_evento
		SET id_processo=98302, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:30.056', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192596;
		UPDATE core.tb_processo_evento
		SET id_processo=64602, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:30.256', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192597;
		UPDATE core.tb_processo_evento
		SET id_processo=72150, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:30.376', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192598;
		UPDATE core.tb_processo_evento
		SET id_processo=3477, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:30.450', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192599;
		UPDATE core.tb_processo_evento
		SET id_processo=9452, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:30.516', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192600;
		UPDATE core.tb_processo_evento
		SET id_processo=57651, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:30.600', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192601;
		UPDATE core.tb_processo_evento
		SET id_processo=29137, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:30.674', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192602;
		UPDATE core.tb_processo_evento
		SET id_processo=9738, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:30.768', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192603;
		UPDATE core.tb_processo_evento
		SET id_processo=84557, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:30.853', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192604;
		UPDATE core.tb_processo_evento
		SET id_processo=91616, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:30.957', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192605;
		UPDATE core.tb_processo_evento
		SET id_processo=83143, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:31.060', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192606;
		UPDATE core.tb_processo_evento
		SET id_processo=83057, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:31.143', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192607;
		UPDATE core.tb_processo_evento
		SET id_processo=82972, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:31.215', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192608;
		UPDATE core.tb_processo_evento
		SET id_processo=80267, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:31.287', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192609;
		UPDATE core.tb_processo_evento
		SET id_processo=75404, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:31.362', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192610;
		UPDATE core.tb_processo_evento
		SET id_processo=75402, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:31.436', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192611;
		UPDATE core.tb_processo_evento
		SET id_processo=80447, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:31.528', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192612;
		UPDATE core.tb_processo_evento
		SET id_processo=80452, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:31.608', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192613;
		UPDATE core.tb_processo_evento
		SET id_processo=75414, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:31.814', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192615;
		UPDATE core.tb_processo_evento
		SET id_processo=86385, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:31.956', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192616;
		UPDATE core.tb_processo_evento
		SET id_processo=2397, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:32.126', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192617;
		UPDATE core.tb_processo_evento
		SET id_processo=78105, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:32.341', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192618;
		UPDATE core.tb_processo_evento
		SET id_processo=67634, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:32.497', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192619;
		UPDATE core.tb_processo_evento
		SET id_processo=99185, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:32.669', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192620;
		UPDATE core.tb_processo_evento
		SET id_processo=97173, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:32.772', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192621;
		UPDATE core.tb_processo_evento
		SET id_processo=99488, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:32.901', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192622;
		UPDATE core.tb_processo_evento
		SET id_processo=96537, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:33.019', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192623;
		UPDATE core.tb_processo_evento
		SET id_processo=98945, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:33.136', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192624;
		UPDATE core.tb_processo_evento
		SET id_processo=88043, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:33.281', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192625;
		UPDATE core.tb_processo_evento
		SET id_processo=79538, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:33.458', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192626;
		UPDATE core.tb_processo_evento
		SET id_processo=79463, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:33.575', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192627;
		UPDATE core.tb_processo_evento
		SET id_processo=88908, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:33.676', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192628;
		UPDATE core.tb_processo_evento
		SET id_processo=83036, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:33.767', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192629;
		UPDATE core.tb_processo_evento
		SET id_processo=60475, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:33.878', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192630;
		UPDATE core.tb_processo_evento
		SET id_processo=88271, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:33.992', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192631;
		UPDATE core.tb_processo_evento
		SET id_processo=80685, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:34.159', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192632;
		UPDATE core.tb_processo_evento
		SET id_processo=82128, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:34.379', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192633;
		UPDATE core.tb_processo_evento
		SET id_processo=83094, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:34.683', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192634;
		UPDATE core.tb_processo_evento
		SET id_processo=81276, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:35.020', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192635;
		UPDATE core.tb_processo_evento
		SET id_processo=79249, id_evento=1000000007, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:35.143', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - pedido de vista', ds_texto_final_interno='Deliberado em sessão - pedido de vista', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - pedido de vista', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192636;
		UPDATE core.tb_processo_evento
		SET id_processo=54352, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:35.363', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192637;
		UPDATE core.tb_processo_evento
		SET id_processo=79279, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:35.474', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192638;
		UPDATE core.tb_processo_evento
		SET id_processo=92980, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:35.592', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192639;
		UPDATE core.tb_processo_evento
		SET id_processo=63939, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:35.694', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192640;
		UPDATE core.tb_processo_evento
		SET id_processo=74610, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:35.841', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192641;
		UPDATE core.tb_processo_evento
		SET id_processo=78577, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:35.995', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192642;
		UPDATE core.tb_processo_evento
		SET id_processo=72325, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:36.102', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192643;
		UPDATE core.tb_processo_evento
		SET id_processo=76547, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:36.210', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192644;
		UPDATE core.tb_processo_evento
		SET id_processo=49695, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:36.312', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192645;
		UPDATE core.tb_processo_evento
		SET id_processo=75025, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:36.470', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192646;
		UPDATE core.tb_processo_evento
		SET id_processo=52266, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:36.563', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192647;
		UPDATE core.tb_processo_evento
		SET id_processo=50951, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:36.690', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192648;
		UPDATE core.tb_processo_evento
		SET id_processo=67184, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:36.856', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192649;
		UPDATE core.tb_processo_evento
		SET id_processo=67186, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:36.937', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192650;
		UPDATE core.tb_processo_evento
		SET id_processo=70901, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.039', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192651;
		UPDATE core.tb_processo_evento
		SET id_processo=74100, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.127', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192652;
		UPDATE core.tb_processo_evento
		SET id_processo=77040, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.212', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192653;
		UPDATE core.tb_processo_evento
		SET id_processo=60953, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.293', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192654;
		UPDATE core.tb_processo_evento
		SET id_processo=52632, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.379', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192655;
		UPDATE core.tb_processo_evento
		SET id_processo=70528, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.462', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192656;
		UPDATE core.tb_processo_evento
		SET id_processo=99558, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.558', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192657;
		UPDATE core.tb_processo_evento
		SET id_processo=97617, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.644', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192658;
		UPDATE core.tb_processo_evento
		SET id_processo=99090, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.720', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192659;
		UPDATE core.tb_processo_evento
		SET id_processo=88696, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.804', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192660;
		UPDATE core.tb_processo_evento
		SET id_processo=67056, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.889', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192661;
		UPDATE core.tb_processo_evento
		SET id_processo=70525, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:37.984', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192662;
		UPDATE core.tb_processo_evento
		SET id_processo=618, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:38.067', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192663;
		UPDATE core.tb_processo_evento
		SET id_processo=84918, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:38.192', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192664;
		UPDATE core.tb_processo_evento
		SET id_processo=98193, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:38.292', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192665;
		UPDATE core.tb_processo_evento
		SET id_processo=70514, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:38.377', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192666;
		UPDATE core.tb_processo_evento
		SET id_processo=58748, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:38.502', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192667;
		UPDATE core.tb_processo_evento
		SET id_processo=76181, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:38.592', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192668;
		UPDATE core.tb_processo_evento
		SET id_processo=96259, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:38.691', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192669;
		UPDATE core.tb_processo_evento
		SET id_processo=54513, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:38.781', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192670;
		UPDATE core.tb_processo_evento
		SET id_processo=98096, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:38.941', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192671;
		UPDATE core.tb_processo_evento
		SET id_processo=68632, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:39.072', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192672;
		UPDATE core.tb_processo_evento
		SET id_processo=83527, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:39.160', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192673;
		UPDATE core.tb_processo_evento
		SET id_processo=80937, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:39.264', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192674;
		UPDATE core.tb_processo_evento
		SET id_processo=75876, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:39.393', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192675;
		UPDATE core.tb_processo_evento
		SET id_processo=56046, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:39.525', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192676;
		UPDATE core.tb_processo_evento
		SET id_processo=70638, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:39.636', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192677;
		UPDATE core.tb_processo_evento
		SET id_processo=68825, id_evento=1000000007, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:39.750', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - pedido de vista', ds_texto_final_interno='Deliberado em sessão - pedido de vista', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - pedido de vista', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192678;
		UPDATE core.tb_processo_evento
		SET id_processo=66490, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:39.990', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192679;
		UPDATE core.tb_processo_evento
		SET id_processo=100564, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:40.171', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192680;
		UPDATE core.tb_processo_evento
		SET id_processo=95882, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:40.346', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192681;
		UPDATE core.tb_processo_evento
		SET id_processo=95873, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:40.490', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192682;
		UPDATE core.tb_processo_evento
		SET id_processo=99490, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:40.754', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192683;
		UPDATE core.tb_processo_evento
		SET id_processo=43281, id_evento=1000000007, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:40.863', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - pedido de vista', ds_texto_final_interno='Deliberado em sessão - pedido de vista', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - pedido de vista', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192684;
		UPDATE core.tb_processo_evento
		SET id_processo=94385, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:40.950', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192685;
		UPDATE core.tb_processo_evento
		SET id_processo=95949, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:41.037', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192686;
		UPDATE core.tb_processo_evento
		SET id_processo=99343, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:41.123', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192687;
		UPDATE core.tb_processo_evento
		SET id_processo=89929, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:41.206', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192688;
		UPDATE core.tb_processo_evento
		SET id_processo=96871, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:41.282', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192689;
		UPDATE core.tb_processo_evento
		SET id_processo=99059, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:41.358', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192690;
		UPDATE core.tb_processo_evento
		SET id_processo=66649, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:41.432', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192691;
		UPDATE core.tb_processo_evento
		SET id_processo=97287, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:41.539', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192692;
		UPDATE core.tb_processo_evento
		SET id_processo=93704, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:41.674', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192693;
		UPDATE core.tb_processo_evento
		SET id_processo=94680, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:41.801', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192694;
		UPDATE core.tb_processo_evento
		SET id_processo=87333, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:41.989', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192695;
		UPDATE core.tb_processo_evento
		SET id_processo=99108, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:43.017', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192696;
		UPDATE core.tb_processo_evento
		SET id_processo=81338, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:43.216', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192698;
		UPDATE core.tb_processo_evento
		SET id_processo=77682, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:43.457', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192699;
		UPDATE core.tb_processo_evento
		SET id_processo=97151, id_evento=1000000000, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:43.745', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - julgado', ds_texto_final_interno='Deliberado em sessão - julgado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - julgado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192700;
		UPDATE core.tb_processo_evento
		SET id_processo=90781, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:44.066', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192701;
		UPDATE core.tb_processo_evento
		SET id_processo=77964, id_evento=1000000006, id_usuario=7870, dt_atualizacao='2018-08-16 13:18:44.543', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Deliberado em sessão - adiado', ds_texto_final_interno='Deliberado em sessão - adiado', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Deliberado em sessão - adiado', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
		WHERE id_processo_evento=3192702;

		SELECT PROCESSO_EVENTO_.ID_PROCESSO
			FROM TB_PROCESSO_EVENTO PROCESSO_EVENTO_
			WHERE ID_PROCESSO IN ( 
				SELECT ID_PROCESSO_TRF TB_PROCESSO_TRF
				FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF
				WHERE ID_SESSAO = 491
				AND ID_USUARIO = 7870
				AND ( TO_CHAR( DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI' ) = '2018-08-16 13:18' ) 
			);

			SELECT * FROM TB_PROCESSO_EVENTO WHERE (TO_CHAR( DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18') AND ID_USUARIO = 7870;

			BEGIN TRANSACTION ;
				SELECT * FROM CORE.TB_PROCESSO_EVENTO
				WHERE ID_PROCESSO IN(
					SELECT ID_PROCESSO_TRF 
				    FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF 
				    WHERE ID_SESSAO = 491
				)
				AND ID_USUARIO = 7870
				AND (TO_CHAR( DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18');
			COMMIT TRANSACTION ;


	### [PC-1415] SCRIPT DE CORRECAO

		BEGIN TRANSACTION ;
			UPDATE CORE.TB_PROCESSO_EVENTO
			SET DT_ATUALIZACAO = '2018-08-15 00:00:00'
			WHERE ID_PROCESSO IN(
				SELECT ID_PROCESSO_TRF 
			    FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF 
			    WHERE ID_SESSAO = 491
			)
			AND ID_USUARIO = 7870
			AND (TO_CHAR( DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18');
		COMMIT TRANSACTION ;

#### [|]
#### [|]
#### [|]
#### [|]
#### [|]
#### [|]
#### [|]
#### [|]
#### [|]
#### [|]
#### [|]
#### [|]
#### [|]
#### [|]
#### [|]


#### [https://sgo.basis.com.br/browse/BASIS-53077 | ]

	### SCRIPT DE ANALISE
		/* 
		José Quintino da Silva Junior, a Secretaria Processual precisa arquivar o processo mas AS tarefas não foram encerradas. 
		Fazer um script que feche AS tarefas DO gabinete deverá permanece somente a tarefa de Minutar ato.
		Processo: 1393-62
		*/

		BEGIN TRANSACTION;

			-- SELECT * FROM TB_PROCESSO WHERE NR_PROCESSO ILIKE '%1393-62%'; -- 61400	0001393-62.2015.2.00.0000
			-- PROCESSO NUMERO : 0001393-62.2015.2.00.0000                    --CTRL + F - SUBSTITUIR TODOS
			
			--SELECT DE TODAS AS TAREFAS DO PROCESSO
			/*
				SELECT *
				FROM JBPM_TASKINSTANCE TASK
				INNER JOIN JBPM_VARIABLEINSTANCE VAR ON
				TASK.PROCINST_ = VAR.PROCESSINSTANCE_
				AND VAR.CLASS_ ILIKE 'L'
				AND VAR.NAME_ ILIKE 'PROCESSO'
				AND VAR.LONGVALUE_ = ( SELECT ID_PROCESSO
				FROM CORE.TB_PROCESSO
				WHERE NR_PROCESSO LIKE '%0001393-62.2015.2.00.0000%' )
				ORDER BY TASK.ID_ DESC;
			*/

			--FECHAR A(S) TASKINSTANCE DA(S) TAREFA(S) ATUALMENTE ABERTA(S) - ANTIGAS
			--SELECT DA TAREFA ABERTA DO PROCESSO
			 /*
				SELECT *
				FROM JBPM_TASKINSTANCE TASK
				INNER JOIN JBPM_VARIABLEINSTANCE VAR ON
				TASK.PROCINST_ = VAR.PROCESSINSTANCE_
				AND VAR.CLASS_ ILIKE 'L'
				AND VAR.NAME_ ILIKE 'PROCESSO'
				AND VAR.LONGVALUE_ = ( SELECT ID_PROCESSO
				FROM CORE.TB_PROCESSO
				WHERE NR_PROCESSO LIKE '%0001393-62.2015.2.00.0000%' )
				AND END_ IS NULL
				ORDER BY TASK.ID_;
				
				-- VOLTAR PARA A TAREFA: 'Minutar ato'          --CTRL + F - SUBSTITUIR TODOS
				-- ID_TASK_INSTANCE (ID_) = 20397220            --CTRL + F - SUBSTITUIR TODOS
		    */

			-- FECHAR TAREFAS DO PROCESSO --PROCESSO FICA SEM NO
				UPDATE JBPM_TASKINSTANCE 
				SET START_ = NOW(), END_ = NOW(), ISOPEN_ = FALSE, ISSIGNALLING_ = FALSE 
				WHERE ID_ IN(5594175,5594188,5594201,5594227,5594240,5594253,5594266,5594279,5594292,5594305,5594318,5594331,5594344,5729057,7039733,
							 7039746,7039759,7039772,7039785,7039811,7039824,7039837,7039850,7039863,7039876,7039889,7039902,8112104,20397220);                         
				
			--REABRIR O NÓ DESEJADO
			--TAREFA QUE SE QUER REABRIR
			 /*
				SELECT *
				FROM JBPM_TASKINSTANCE TASK
				INNER JOIN JBPM_VARIABLEINSTANCE VAR ON
				TASK.PROCINST_ = VAR.PROCESSINSTANCE_
				AND VAR.CLASS_ ILIKE 'L'
				AND VAR.NAME_ ILIKE 'PROCESSO'
				AND VAR.LONGVALUE_ = ( SELECT ID_PROCESSO
				FROM CORE.TB_PROCESSO
				WHERE NR_PROCESSO LIKE '%0001393-62.2015.2.00.0000%' )
				AND TASK.NAME_ ILIKE 'Minutar ato'
				ORDER BY TASK.ID_ DESC
				LIMIT 1;
			*/
			
			-- ABRIR TAREFA
				UPDATE JBPM_TASKINSTANCE SET END_ = NULL, ISOPEN_ = TRUE, ISSIGNALLING_ = TRUE WHERE ID_ = 20397220;

			
			-- DAR NOVO SELECT DA TAREFA QUE SE QUER REABRIR NA TASKINSTANCE E ANOTAR OS VALORES DA: TASK, TOKEN, PROCESSINSTANCE E ID_PROCESSO 
			 /*
				SELECT TASK_, TASK.TOKEN_, PROCINST_, LONGVALUE_
				FROM JBPM_TASKINSTANCE TASK
				INNER JOIN JBPM_VARIABLEINSTANCE VAR ON
				TASK.PROCINST_ = VAR.PROCESSINSTANCE_
				AND VAR.CLASS_ ILIKE 'L'
				AND VAR.NAME_ ILIKE 'PROCESSO'
				AND VAR.LONGVALUE_ = ( SELECT ID_PROCESSO
				FROM CORE.TB_PROCESSO
				WHERE NR_PROCESSO LIKE '%0001393-62.2015.2.00.0000%' )
				AND TASK.NAME_ ILIKE 'MINUTAR ATO'
				ORDER BY TASK.ID_ DESC
				LIMIT 1;
			*/
				--TASK 				 20435082 					--CTRL + F - SUBSTITUIR TODOS
				--TOKEN 			 5523834 					--CTRL + F - SUBSTITUIR TODOS
				--PROCESSINSTANCE    5523833 					--CTRL + F - SUBSTITUIR TODOS
				--ID PROCESSO 		 61400						--CTRL + F - SUBSTITUIR TODOS
				
			--PEGAR VALORES DA TASKNODE
				--SELECT TASKNODE_ FROM JBPM_TASK WHERE ID_ = 20435082;
						
					--TASK NODE_             20435061                   --CTRL + F - SUBSTITUIR TODOS
					
			--ATUALIZAR O TOKEN
				-- SELECT * FROM JBPM_TOKEN WHERE ID_ IN (5523834); --TOKEN 
				UPDATE JBPM_TOKEN SET END_ = NULL, ISABLETOREACTIVATEPARENT_ = TRUE, NODE_ = 20435061, PROCESSINSTANCE_ = 5523833 WHERE ID_ = 5523834;
				
			-- ATUALIZAR O ID DO PROCESSO E A O ID DA PROCINSTACE
				--SELECT * FROM CORE.TB_PROCESSO_INSTANCE WHERE ID_PROCESSO = 61400 AND ID_PROC_INST = 5523833;
				UPDATE CORE.TB_PROCESSO_INSTANCE 
			    SET IN_ATIVO = TRUE 
			    WHERE ID_PROCESSO = 61400 
			    AND ID_PROC_INST = 5523833;

			-- INSERE DADOS PARA DA LOCALIZACAO DA TAREFA			
				INSERT INTO CORE.TB_PROC_LOCALIZACAO_IBPM VALUES ((SELECT NEXTVAL( 'CORE.SQ_TB_PROC_LOCALIZACAO_IBPM' )), 20435082, 5523833, 61400, 9, 1338);
				
					-- SELECT * FROM TB_PROCESSO_TAREFA WHERE ID_PROCESSO_TAREFA = 20397220;
					-- SELECT * FROM TB_ORGAO_JULGADOR;	
					-- SELECT CREATE_ FROM JBPM_TASKINSTANCE WHERE ID_ = 20397220;

			-- POPULAR A TABELA DE TAREFAS NO PROCESSO	
				-- EXECUTAR ESSE APENAS SE 'ID_PROCESSO_TAREFA' NAO EXISTIR	
				INSERT INTO CLIENT.TB_PROCESSO_TAREFA(ID_PROCESSO_TAREFA, 
													  ID_LOTE, 
													  NM_FLUXO, 
													  NM_TAREFA, 
													  ID_TAREFA, 
													  ID_CAIXA, 
													  NM_CAIXA, 
													  ID_PROCESSO_TRF, 
				                                      IN_SEGREDO_JUSTICA, 
				                                      IN_APRECIADO_SEGREDO, 
				                                      ID_PROCESS_INSTANCE, 
				                                      ID_TASK_INSTANCE, 
				                                      ID_TASK, 
				                                      NM_ACTORID, 
				                                      ID_ORGAO_JULGADOR, 
				                                      ID_ORGAO_JULGADOR_COLEGIADO, 
				                                      ID_CARGO, 
				                                      ID_ORGAO_JULGADOR_CARGO, 
				                                      DT_CREATE_TASK, 
				                                      ID_PREVIOUS_TASK, 
				                                      VL_PRIORIDADE)
				VALUES (20397220, NULL, NULL, 'Minutar ato', 11, NULL, NULL, 61400, FALSE, 'N', 5523833, 20397220, 20435082, 
			            NULL, 14, 2, 2, 8, '2018-08-13 18:56:54', NULL, 0);
		COMMIT TRANSACTION;		
	            		

	### SCRIPT DE CORRECAO

		BEGIN TRANSACTION;

		-- FECHAR TAREFA(S) DO PROCESSO COM ESSA ACAO O PROCESSO FICA SEM NO
			UPDATE JBPM_TASKINSTANCE 
			SET START_ = NOW(), END_ = NOW(), ISOPEN_ = FALSE, ISSIGNALLING_ = FALSE 
			WHERE ID_ IN(5594175,5594188,5594201,5594227,5594240,5594253,5594266,5594279,5594292,5594305,5594318,5594331,5594344,5729057,7039733,
						 7039746,7039759,7039772,7039785,7039811,7039824,7039837,7039850,7039863,7039876,7039889,7039902,8112104,20397220);                         --CTRL + F - SUBSTITUIR TODOS
		
		-- ABRIR A TAREFA DESEJADA 
			UPDATE JBPM_TASKINSTANCE SET END_ = NULL, ISOPEN_ = TRUE, ISSIGNALLING_ = TRUE WHERE ID_ = 20397220;

		--ATUALIZAR O TOKEN
			UPDATE JBPM_TOKEN SET END_ = NULL, ISABLETOREACTIVATEPARENT_ = TRUE, NODE_ = 20435061, PROCESSINSTANCE_ = 5523833 WHERE ID_ = 5523834;
			
		-- ATUALIZAR O ID DO PROCESSO E A O ID DA PROCINSTACE
			UPDATE CORE.TB_PROCESSO_INSTANCE 
		    SET IN_ATIVO = TRUE 
		    WHERE ID_PROCESSO = 61400 
		    AND ID_PROC_INST = 5523833;
		   
		-- INSERE DADOS PARA DA LOCALIZACAO DA TAREFA
			INSERT INTO CORE.TB_PROC_LOCALIZACAO_IBPM VALUES ((SELECT NEXTVAL( 'CORE.SQ_TB_PROC_LOCALIZACAO_IBPM' )), 20435082, 5523833, 61400, 9, 1338);

		-- POPULAR A TABELA DE TAREFAS NO PROCESSO
			-- EXECUTAR ESSE APENAS SE 'ID_PROCESSO_TAREFA' NAO EXISTIR	
			INSERT INTO CLIENT.TB_PROCESSO_TAREFA(ID_PROCESSO_TAREFA, 
												  ID_LOTE, 
												  NM_FLUXO, 
												  NM_TAREFA, 
												  ID_TAREFA, 
												  ID_CAIXA, 
												  NM_CAIXA, 
												  ID_PROCESSO_TRF, 
			                                      IN_SEGREDO_JUSTICA, 
			                                      IN_APRECIADO_SEGREDO, 
			                                      ID_PROCESS_INSTANCE, 
			                                      ID_TASK_INSTANCE, 
			                                      ID_TASK, 
			                                      NM_ACTORID, 
			                                      ID_ORGAO_JULGADOR, 
			                                      ID_ORGAO_JULGADOR_COLEGIADO, 
			                                      ID_CARGO, 
			                                      ID_ORGAO_JULGADOR_CARGO, 
			                                      DT_CREATE_TASK, 
			                                      ID_PREVIOUS_TASK, 
			                                      VL_PRIORIDADE)
			VALUES (20397220, NULL, NULL, 'Minutar ato', 11, NULL, NULL, 61400, FALSE, 'N', 5523833, 20397220, 20435082, 
		            NULL, 14, 2, 2, 8, '2018-08-13 18:56:54', NULL, 0);
		            
		COMMIT TRANSACTION;

	#### [https://git.cnj.jus.br/pje/pje/tree/PJEVII-2542]

		# REALIZAR CHERRY-PICK PARA A DEMANDA PJEVII-2542

			-- ACESSAR A BRANCH DE DESTINO PARA FAZER CHERRY-PICK COM O IDENTIFICADOR DA BRANCH.
				> git fetch origin           									// ATUALIAZAR A BRANCH LOCAL COM AS NOVAS BRANCHS DA 'ORIGIN/MASTER'
				> git checkout 2.0.0.7_cnj 
				> git cherry-pick 74f38829b1d5de46ccf26f7d92069ce70d773b16 		// LOG DO COMMIT A SER INSERIDO
				> git cherry-pick --continue 									// CONTINUAR O PROCESSO DE CHERRY-PICK
					> CTRL + O
					> CTRL + X
				> git push origin 2.0.0.7_cnj

	### [PC-1415] http://www.cnj.jus.br/jira/browse/PC-1415

		### SCRIPT DE ANALISE

		SELECT DISTINCT NSPNAME, RELNAME
			FROM PG_NAMESPACE N, PG_CLASS C, PG_ATTRIBUTE A, PG_TYPE T
			WHERE N.OID = C.RELNAMESPACE
			AND C.RELKIND ILIKE 'R'
			AND A.ATTNUM > 0
			AND NOT A.ATTISDROPPED
			AND A.ATTRELID = C.OID
			AND A.ATTTYPID = T.OID
			AND C.RELNAME ILIKE '%TB_PARAMETRO%'
			ORDER BY NSPNAME, RELNAME;

			SELECT NSPNAME, RELNAME, ATTNAME
			FROM PG_NAMESPACE N, PG_CLASS C, PG_ATTRIBUTE A, PG_TYPE T
			WHERE N.OID = C.RELNAMESPACE
			AND C.RELKIND ILIKE 'R'
			AND A.ATTNUM > 0
			AND NOT A.ATTISDROPPED
			AND A.ATTRELID = C.OID
			AND A.ATTTYPID = T.OID
			AND A.ATTNAME ILIKE '%JULGAMENTO%'
			ORDER BY NSPNAME, RELNAME, ATTNAME;
					
			BEGIN TRANSACTION;
				UPDATE ACL.TB_USUARIO_LOGIN 
				SET DS_SENHA = '$2a$12$Xmr6b9QcSf/6uep1axnV9OV3UUI5yQHlNBRuKB/Et9VpqedzE25Ee', 
				    IN_STATUS_SENHA = 'A', 
				    DT_VALIDADE_SENHA = '2020-01-01'
				WHERE DS_LOGIN IN ('01547345195', '88940764153');
			COMMIT TRANSACTION;

			SELECT * FROM TB_USUARIO_LOGIN WHERE DS_LOGIN ILIKE '%01547345195%';

			SELECT * FROM TB_PROCESSO_DOCUMENTO_BIN WHERE DS_CERT_CHAIN IS NULL ORDER BY ID_PROCESSO_DOCUMENTO_BIN DESC;

			SELECT *
			FROM JBPM_TASKINSTANCE TASK
			INNER JOIN JBPM_VARIABLEINSTANCE VAR ON
			TASK.PROCINST_ = VAR.PROCESSINSTANCE_
			AND VAR.CLASS_ ILIKE 'L'
			AND VAR.NAME_ ILIKE 'PROCESSO'
			AND VAR.LONGVALUE_ = ( SELECT ID_PROCESSO
			FROM CORE.TB_PROCESSO
			WHERE NR_PROCESSO LIKE '%0004897-71.2018.2.00.0000%' )
			ORDER BY TASK.ID_ DESC;
					
			SELECT *
			FROM JBPM_TASKINSTANCE TASK
			INNER JOIN JBPM_VARIABLEINSTANCE VAR ON
			TASK.PROCINST_ = VAR.PROCESSINSTANCE_
			AND VAR.CLASS_ ILIKE 'L'
			AND VAR.NAME_ ILIKE 'PROCESSO'
			AND VAR.LONGVALUE_ = ( SELECT ID_PROCESSO
			FROM CORE.TB_PROCESSO
			WHERE NR_PROCESSO LIKE '%0004897-71.2018.2.00.0000%' )
			AND END_ IS NULL
			ORDER BY TASK.ID_;

			-- REMOVER DATA DE MANIFESTACAO PARA O PROCESSO '4897-71'
			SELECT * FROM TB_PROCESSO WHERE NR_PROCESSO ILIKE '%0004897-71.2018.2.00.0000%'; -- 105478	0004897-71.2018.2.00.0000

			SELECT * FROM TB_PROC_PARTE_EXPEDIENTE WHERE ID_PROCESSO_TRF = 105478;
			--UPDATE client.tb_proc_parte_expediente SET id_pessoa_parte = 7496, id_processo_expediente = 356554, dt_ciencia_parte = '2018-07-25 15:41:16.135', qt_prazo_legal_parte = 15, dt_prazo_legal_parte = '2018-08-15 23:59:59.000', qt_prazo_processual_parte = NULL, dt_prazo_processual_parte = '2018-07-25 15:22:25.239', in_ciencia_sistema = FALSE, id_pessoa_ciencia = 126025, nm_pessoa_parte = 'Corregedoria-Geral da Justiça do Estado de São Paulo', nm_pessoa_ciencia = 'RONALDO ITIKAWA', in_pendente_manifestacao = FALSE, id_resposta = 55762, ds_pendencia = NULL, in_fechado = TRUE, in_tipo_prazo = 'D', id_processo_trf = 105478, ds_recibo_dje = NULL, in_intima_pessoal = FALSE, id_procuradoria = 13, in_destaque = TRUE, cod_tipo_calc_meio_comunicacao = 'CD'
			WHERE id_processo_parte_expediente = 518032;
			--UPDATE client.tb_proc_parte_expediente SET id_pessoa_parte = 7496, id_processo_expediente = 370883, dt_ciencia_parte = '2018-08-13 11:13:40.123', qt_prazo_legal_parte = NULL, dt_prazo_legal_parte = '2018-08-20 23:59:59.000', qt_prazo_processual_parte = NULL, dt_prazo_processual_parte = NULL, in_ciencia_sistema = FALSE, id_pessoa_ciencia = 160985, nm_pessoa_parte = 'Corregedoria-Geral da Justiça do Estado de São Paulo', nm_pessoa_ciencia = 'LEONARDO DE OLIVEIRA SILVANY', in_pendente_manifestacao = FALSE, id_resposta = 56673, ds_pendencia = NULL, in_fechado = TRUE, in_tipo_prazo = 'S', id_processo_trf = 105478, ds_recibo_dje = NULL, in_intima_pessoal = FALSE, id_procuradoria = 13, in_destaque = TRUE, cod_tipo_calc_meio_comunicacao = 'CD'
			WHERE id_processo_parte_expediente = 555654;

			-- VERIFICA QUAIS PROCESSOS ESTAO COM DATA DE MANIFESTACAO, POREM 'SEM PRAZO'
			SELECT COUNT(*) FROM TB_PROC_PARTE_EXPEDIENTE WHERE QT_PRAZO_LEGAL_PARTE IS NULL AND DT_PRAZO_LEGAL_PARTE IS NOT NULL;

			SELECT * 
			FROM TB_PROC_PARTE_EXPEDIENTE 
			WHERE QT_PRAZO_LEGAL_PARTE IS NULL 
			AND DT_PRAZO_LEGAL_PARTE IS NOT NULL
			AND IN_TIPO_PRAZO = 'S';

			SELECT B.NR_PROCESSO,
			       A.QT_PRAZO_LEGAL_PARTE,
			       A.DT_PRAZO_LEGAL_PARTE
			FROM TB_PROC_PARTE_EXPEDIENTE A 
			INNER JOIN TB_PROCESSO B
			ON A.ID_PROCESSO_EXPEDIENTE = B.ID_PROCESSO
			WHERE QT_PRAZO_LEGAL_PARTE IS NULL 
			AND DT_PRAZO_LEGAL_PARTE IS NOT NULL
			AND B.NR_PROCESSO IS NOT NULL
			AND A.IN_TIPO_PRAZO = 'S';

			SELECT *tb_tp_situacao_julgamento
			FROM TB_PROC_PARTE_EXPEDIENTE
			WHERE COD_TIPO_CALC_MEIO_COMUNICACAO = 'CD';

			SELECT B.NR_PROCESSO,
				   A.ID_PROCESSO_TRF,	
			       A.QT_PRAZO_LEGAL_PARTE,
			       A.DT_PRAZO_LEGAL_PARTE,
			       A.IN_TIPO_PRAZO
			FROM TB_PROC_PARTE_EXPEDIENTE A 
			INNER JOIN TB_PROCESSO Bsessao
			ON A.ID_PROCESSO_EXPEDIENTE = B.ID_PROCESSO
			WHERE A.COD_TIPO_CALC_MEIO_COMUNICACAO = 'CD';

			SELECT * FROM TB_PROC_PARTE_EXPEDIENTE WHERE ID_PROCESSO_TRF IN (31646,596,2008,528);

			BEGIN TRANSACTION ;
				--UPDATE TB_PROC_PARTE_EXPEDIENTE 
				SET DT_PRAZO_LEGAL_PARTE = NULL
				WHERE ID_PROCESSO_TRF = 105478
				AND ID_PROCESSO_PARTE_EXPEDIENTE = 555654;
			COMMIT TRANSACTION ;
				
			BEGIN TRANSACTION;
				-- 
			COMMIT TRANSACTION;

			SELECT * FROM TB_PARAMETRO;

			SELECT * FROM TB_PROCESSO WHERE ID_PROCESSO = 967;

			-- ### REORDENAR AS MOVIMENTACOES PARA OS '136' PROCESSOS REFERENTE A SESSAO '491 - 49ª Sessão Extraordinária' DO DIA '14/08/2018'
			SELECT * FROM TB_SESSAO WHERE DS_APELIDO ILIKE '%49ª Sessão Extraordinária%';

			-- LOCALIZAR TODO OS PROCESSOS DA SESSAO
			SELECT COUNT(*) FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491;

			SELECT * FROM TB_PROCESSO WHERE ID_PROCESSO = 90781;

			SELECT * FROM TB_PROCESSO WHERE NR_PROCESSO ILIKE '0000676-16.2016.2.00.0000';

			SELECT * FROM TB_PROCESSO_EVENTO WHERE ID_PROCESSO = 90781 ORDER BY DT_ATUALIZACAO DESC;

			SELECT * FROM TB_PROCESSO_EVENTO WHERE (TO_CHAR(DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18') AND ID_USUARIO = 7870;

			SELECT * FROM TB_PROCESSO_EVENTO WHERE (TO_CHAR(DT_ATUALIZACAO::DATE, 'YYYY-MM-DD HH24:MI:SS') = '2018-08-16 13:18:30');

			SELECT * FROM TB_PROCESSO_EVENTO WHERE ID_PROCESSO = 90781 AND DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30' AND ID_EVENTO = 1000000006;

			SELECT * FROM TB_PROCESSO_EVENTO WHERE DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30';

			SELECT * FROM CORE.TB_EVENTO WHERE ID_EVENTO = 1000000006 ;
			SELECT * FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491 ORDER BY TP_SITUACAO_JULGAMENTO;
			SELECT * FROM TB_PROCESSO_EVENTO WHERE ID_PROCESSO = 9452 AND DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30';
			SELECT * FROM TB_PROCESSO_EVENTO WHERE ID_PROCESSO = 72150 AND DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30';
			SELECT * FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491;

			SELECT * FROM TB_processo_TRF;

			SELECT TP_SITUACAO_JULGAMENTO FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491 AND ID_PROCESSO_TRF IN ( 90781, 77964, 103964, 95036, 97151, 85204, 81247, 90539, 93522, 102311, 98598, 92008, 101724, 100412, 75927, 101042, 81458, 81923, 83681, 85818, 86079, 87531, 87460, 102394, 88644, 89897, 96537, 92193, 94807, 99510, 95873, 94385, 99343, 99059, 99108, 98621, 86926, 93584, 92561, 105930, 3477, 98945, 88271, 54352, 60953, 70514, 95882, 96871, 66649, 80937, 56046, 98302, 72325, 58748, 68632, 68825, 66490, 64602, 80452, 67634, 99185, 75876, 72150, 57651, 86385, 52266, 50951, 74100, 77040, 97617, 99090, 54513, 81338, 91616, 9452, 76181, 83057, 75404, 79463, 88908, 83036, 83094, 79279, 76547, 49695, 75025, 67186, 70901, 88696, 67056, 618, 100564, 83143, 9137, 84557, 2397, 78105, 9738, 75414, 82972, 80267, 75402, 80447, 97173, 87333, 82128, 99488, 88043, 60475, 79249, 98193, 80685, 43281, 81276, 74610, 78577, 67184, 70528, 99558, 96259, 99490, 94680, 98096, 70638, 92980, 63939, 52632, 70525, 84918, 83527, 95949, 89929, 97287, 93704, 77682, 79538 ) ORDER BY TP_SITUACAO_JULGAMENTO;

			SELECT COUNT(*) FROM CLIENT.TB_PROCESSO_TRF WHERE ID_PROCESSO_TRF IN (90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927,
								101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510,
								95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
								95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
								72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
								79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
								84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
								98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
								52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);
							
							
							
			SELECT * FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491 AND ID_PROCESSO_TRF = 9452;				
							
			SELECT * FROM TB_PROCESSO_EVENTO WHERE ID_PROCESSO = 9452 AND (TO_TIMESTAMP(DT_ATUALIZACAO::DATE, 'YYYY-MM-DD HH24:MI:SS'));
			AND DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30';				
							
							
							
			--SELECT  COUNT(*)
			--SELECT  C.ID_EVENTO, A.ID_PROCESSO_TRF
			SELECT A.ID_SESSAO, A.ID_PROCESSO_TRF, C.DT_ATUALIZACAO, C.ID_EVENTO
			FROM TB_SESSAO_PAUTA_PROC_TRF A
			INNER JOIN CLIENT.TB_PROCESSO_TRF B
			ON A.ID_PROCESSO_TRF = B.ID_PROCESSO_TRF
			INNER JOIN CORE.TB_PROCESSO_EVENTO C
			ON C.ID_PROCESSO = B.ID_PROCESSO_TRF
			WHERE A.ID_SESSAO = 491
			AND C.ID_EVENTO IN(1000000006,1000000007,1000000008,1000000000)
			AND C.DT_ATUALIZACAO::DATE = '2018-08-16 13:18'
			AND A.ID_PROCESSO_TRF IN(90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927,
								101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510,
								95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
								95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
								72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
								79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
								84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
								98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
								52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);
							
							
							
			SELECT * FROM CORE.TB_EVENTO WHERE DS_EVENTO ILIKE '%Deliberado em sessão%';
			SELECT * FROM CORE.TB_EVENTO WHERE ID_EVENTO IN(1000000000, 1000000006, 1000000007, 1000000008);

			SELECT COUNT(*) 
			FROM TB_SESSAO_PAUTA_PROC_TRF A
			INNER JOIN CLIENT.TB_PROCESSO_TRF B
			ON A.ID_PROCESSO_TRF = B.ID_PROCESSO_TRF
			INNER JOIN CORE.TB_PROCESSO_EVENTO C
			ON C.ID_PROCESSO = B.ID_PROCESSO_TRF
			WHERE A.ID_SESSAO = 491
			AND (C.ID_EVENTO = 1000000006)
			AND C.DT_ATUALIZACAO::DATE = '2018-08-16 13:18'
			AND A.ID_PROCESSO_TRF IN(90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927,
								101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510,
								95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
								95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
								72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
								79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
								84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
								98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
								52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);


			-- PROCESSOS PAUTADOS NA SESSAO '491 - 49ª Sessão Extraordinária' DO DIA '14/08/2018'
			SELECT COUNT( ID_PROCESSO_TRF )
			FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF
			WHERE ID_SESSAO = 491;

			SELECT * FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491;


			SELECT PROCESSO_EVENTO_.ID_PROCESSO
			FROM TB_PROCESSO_EVENTO PROCESSO_EVENTO_
			WHERE ID_PROCESSO IN (
				SELECT ID_PROCESSO_TRF TB_PROCESSO_TRF
				FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF
				WHERE ID_SESSAO = 491
				AND (TO_CHAR(DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18')
			);

			-- RECUPERAR EVENTOS DA SESSAO PELA DATA E HORA '2018-08-16 13:18:30'
			SELECT *
			FROM TB_PROCESSO A
			INNER JOIN CORE.TB_PROCESSO_EVENTO B
			ON A.ID_PR	AND ID_PROCESSO IN( 90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927
									101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510
									95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
									95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
									72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
									79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
									84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
									98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
									52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);
			COMMIT TRANSACTION ;

			SELECT * FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491 AND ID_PROCESSO_TRF = 72150;OCESSO = B.ID_PROCESSO
			INNER JOIN TB_SESSAO_PAUTA_PROC_TRF C 
			ON C.ID_PROCESSO_TRF = B.ID_PROCESSO
			WHERE C.ID_SESSAO = 491
			AND B.DT_ATUALIZACAO::DATE = '2018-08-16 13:18'
			AND A.id_processo IN (90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927,
								101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510,
								95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
								95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
								72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
								79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
								84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
								98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
								52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);

			--SELECT COUNT(*) 
			SELECT *
			FROM TB_PROCESSO_EVENTO
			WHERE DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30'
			AND ID_PROCESSO IN( 90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927,
								101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510,
								95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
								95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
								72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
								79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
								84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
								98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
								52632,70525,84918,83527,95949,89929,97287,93704,77682,79538) ORDER BY ID_PROCESSO;

			SELECT * FROM TB_PROCESSO_EVENTO WHERE (TO_CHAR(DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18') AND ID_USUARIO = 7870;				
							
			-- ALTERA A MOVIMENTACAO DOS '136' PROCESSOS REFENTES A '491 - 49ª Sessão Extraordinária'
			BEGIN TRANSACTION ;
				--UPDATE TB_PROCESSO_EVENTO
				SET (TO_CHAR(DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18')
				WHERE ID_SESSAO = 491
				AND ID_USUARIO = 7870
				AND ID_PROCESSO IN( 90781,77964,103964,95036,97151,85204,81247,90539,93522,102311,98598,92008,101724,100412,75927
									101042,81458,81923,83681,85818,86079,87531,87460,102394,88644,89897,96537,92193,94807,99510
									95873,94385,99343,99059,99108,98621,86926,93584,92561,105930,3477,98945,88271,54352,60953,70514,
									95882,96871,66649,80937,56046,98302,72325,58748,68632,68825,66490,64602,80452,67634,99185,75876,
									72150,57651,86385,52266,50951,74100,77040,97617,99090,54513,81338,91616,9452,76181,83057,75404,
									79463,88908,83036,83094,79279,76547,49695,75025,67186,70901,88696,67056,618,100564,83143,9137,
									84557,2397,78105,9738,75414,82972,80267,75402,80447,97173,87333,82128,99488,88043,60475,79249,
									98193,80685,43281,81276,74610,78577,67184,70528,99558,96259,99490,94680,98096,70638,92980,63939,
									52632,70525,84918,83527,95949,89929,97287,93704,77682,79538);
			COMMIT TRANSACTION ;

			SELECT * FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO = 491 AND ID_PROCESSO_TRF = 72150;

			-- VERIFICAR QUANTIDADES DOS TIPOS POSSIVEIS 'Deliberado em sessão - julgado', 'Deliberado em sessão - adiado'
			-- OBJETIVO: COLOCAR TODAS AS MOVIMENTAÇÕES DOS PROCESSOS DA SESSAO PARA O DIA '2018-08-16 00:00:00'

			SELECT * FROM TB_PROCESSO_EVENTO WHERE DT_ATUALIZACAO::DATE = '2018-08-16 13:18:30';


			SELECT PROCESSO_EVENTO_.ID_PROCESSO
			FROM TB_PROCESSO_EVENTO PROCESSO_EVENTO_
			WHERE ID_PROCESSO IN ( 
				SELECT ID_PROCESSO_TRF TB_PROCESSO_TRF
				FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF
				WHERE ID_SESSAO = 491
				AND ID_USUARIO = 7870
				AND ( TO_CHAR( DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI' ) = '2018-08-16 13:18' ) 
			);


			SELECT * FROM TB_PROCESSO_EVENTO WHERE (TO_CHAR( DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18') AND ID_USUARIO = 7870;


			BEGIN TRANSACTION ;
				SELECT * FROM CORE.TB_PROCESSO_EVENTO
				WHERE ID_PROCESSO IN(
					SELECT ID_PROCESSO_TRF 
				    FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF 
				    WHERE ID_SESSAO = 491
				)
				AND ID_USUARIO = 7870
				AND (TO_CHAR( DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18');
			COMMIT TRANSACTION ;

		### SCRIPT DE CORREÇÃO

			-- ALTERA A MOVIMENTACAO DOS '136' PROCESSOS REFENTES A '491 - 49ª Sessão Extraordinária'
			BEGIN TRANSACTION ;
				UPDATE CORE.TB_PROCESSO_EVENTO
				SET DT_ATUALIZACAO = '2018-08-15 00:00:00'
				WHERE ID_PROCESSO IN(
					SELECT ID_PROCESSO_TRF 
				    FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF 
				    WHERE ID_SESSAO = 491
				)
				AND ID_USUARIO = 7870
				AND (TO_CHAR( DT_ATUALIZACAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-08-16 13:18');
			COMMIT TRANSACTION ;

	### [PJEVII-2664] http://www.cnj.jus.br/jira/browse/PJEVII-2664

		### SCRIPT DEMANDA

		BEGIN TRANSACTION ;
			INSERT INTO CORE.TB_PARAMETRO (NM_VARIAVEL,DS_VARIAVEL,VL_VARIAVEL,IN_SISTEMA,IN_ATIVO)
				SELECT 'habilitarFerramentaAcessibilidadeRybena', 'Permite habilitar o software de acessibilidade Rybená', false, true, true 
			WHERE NOT EXISTS (SELECT 1 FROM CORE.TB_PARAMETRO WHERE NM_VARIAVEL = 'habilitarFerramentaAcessibilidadeRybena');
		COMMIT TRANSACTION ;
		ROLLBACK TRANSACTION ;

	### [TAYNER] CORRIGIR PROBLEMAS DE MINUTA EM ELABORAÇÃO

		-- VERIFICAR QUAIS PROCESSOS ESTÃO COM O PROBLEMA  DE MINUTA EM ELABORAÇÃO

			SELECT PROC.ID_PROCESSO, PROC.nr_processo
                        FROM JBPM_TASKINSTANCE TASK
                        INNER JOIN JBPM_VARIABLEINSTANCE VAR ON VAR.PROCESSINSTANCE_ = TASK.PROCINST_
                        INNER JOIN CORE.TB_PROCESSO_DOCUMENTO DOC1 ON DOC1.ID_PROCESSO_DOCUMENTO = VAR.LONGVALUE_
                        INNER JOIN CORE.TB_PROCESSO PROC ON PROC.ID_PROCESSO = DOC1.ID_PROCESSO
                        INNER JOIN CLIENT.TB_PROCESSO_TRF TRF ON TRF.ID_PROCESSO_TRF = DOC1.ID_PROCESSO
                        AND (VAR.NAME_ = 'minutaEmElaboracao')
                        AND (VAR.LONGVALUE_ IS NOT NULL)
                        AND EXISTS 
                                (SELECT 1 FROM CORE.TB_PROCESSO_DOCUMENTO DOC
                                        INNER JOIN CLIENT.TB_PROC_DOC_BIN_PESS_ASSIN ASSIN ON ASSIN.ID_PROCESSO_DOCUMENTO_BIN = DOC.ID_PROCESSO_DOCUMENTO_BIN
                                        WHERE DOC.ID_PROCESSO_DOCUMENTO = VAR.LONGVALUE_
                                                AND DOC.DT_JUNTADA IS NOT NULL
                                                AND ASSIN.DT_ASSINATURA IS NOT NULL
                                                AND ASSIN.DS_ASSINATURA IS NOT NULL
                                                AND ASSIN.DS_CERT_CHAIN IS NOT NULL)
                      AND TASK.END_ IS NULL
                      ORDER BY DT_JUNTADA DESC;

		-- APLICAR CORREÇÃO PALIATIVA  DE MINUTA EM ELABORAÇÃO

		BEGIN TRANSACTION ;
			UPDATE JBPM_VARIABLEINSTANCE
			SET LONGVALUE_ = NULL 
			WHERE ID_ 
			        IN (SELECT VAR.ID_
			                FROM JBPM_TASKINSTANCE TASK
			                INNER JOIN JBPM_VARIABLEINSTANCE VAR ON VAR.PROCESSINSTANCE_ = TASK.PROCINST_
			                INNER JOIN CORE.TB_PROCESSO_DOCUMENTO DOC1 ON DOC1.ID_PROCESSO_DOCUMENTO = VAR.LONGVALUE_
			                INNER JOIN CORE.TB_PROCESSO PROC ON PROC.ID_PROCESSO = DOC1.ID_PROCESSO
			                INNER JOIN CLIENT.TB_PROCESSO_TRF TRF ON TRF.ID_PROCESSO_TRF = DOC1.ID_PROCESSO
			                AND (VAR.NAME_ = 'minutaEmElaboracao')
			                AND (VAR.LONGVALUE_ IS NOT NULL)
			                AND EXISTS 
			                        (SELECT 1 FROM CORE.TB_PROCESSO_DOCUMENTO DOC
			                                INNER JOIN CLIENT.TB_PROC_DOC_BIN_PESS_ASSIN ASSIN ON ASSIN.ID_PROCESSO_DOCUMENTO_BIN = DOC.ID_PROCESSO_DOCUMENTO_BIN
			                                WHERE DOC.ID_PROCESSO_DOCUMENTO = VAR.LONGVALUE_
			                                        AND DOC.DT_JUNTADA IS NOT NULL
			                                        AND ASSIN.DT_ASSINATURA IS NOT NULL
			                                        AND ASSIN.DS_ASSINATURA IS NOT NULL
			                                        AND ASSIN.DS_CERT_CHAIN IS NOT NULL)
			              AND TASK.END_ IS NULL
			              ORDER BY DT_JUNTADA DESC
			);
		COMMIT TRANSACTION;


	### [DEMANDA-0000] <LINK>

		### OBJETIVO
			> TRANSLADAR OS '735' DOCUMENTOS DO PROCESSO '0006014-39.2014.2.00.0000' PARA O PROCESSO '0006919-05.2018.2.00.0000'

		### SCRIPT DE ANALISE

			-- PROCESSO DE ORIGEM:   6014-39
			-- PROCESSO DE DESTINO:  6919-05

			SELECT * FROM TB_PROCESSO WHERE NR_PROCESSO ILIKE '%6014-39%';  -- ORIGEM DOS DOCUMENTOS           56046    0006014-39.2014.2.00.0000 
			SELECT * FROM TB_PROCESSO WHERE NR_PROCESSO ILIKE '%6919-05%';  -- DESTINO DOS DOCUMENTOS          108252   0006919-05.2018.2.00.0000

			SELECT COUNT(*) FROM TB_PROCESSO_DOCUMENTO WHERE ID_PROCESSO = 56046;    -- 735
			SELECT COUNT(*) FROM TB_PROCESSO_DOCUMENTO WHERE ID_PROCESSO = 108252;   -- 4

			SELECT * FROM TB_PROCESSO_DOCUMENTO WHERE ID_PROCESSO = 56046;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Despacho', id_processo=56046, id_usuario_inclusao=94570, id_usuario_exclusao=NULL, dt_inclusao='2015-09-15 16:42:41.453', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=63, id_processo_documento_bin=1747952, ds_observacao_procedimento=NULL, id_jbpm_task=7118455, in_documento_sigiloso=false, id_papel=1469, id_usuario_alteracao=11977, id_localizacao=4, ds_nome_usuario_inclusao=NULL, ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2015-09-15 16:50:04.895', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1786190;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Decisão', id_processo=56046, id_usuario_inclusao=93123, id_usuario_exclusao=NULL, dt_inclusao='2015-06-24 18:47:11.067', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=64, id_processo_documento_bin=1698508, ds_observacao_procedimento=NULL, id_jbpm_task=6214261, in_documento_sigiloso=false, id_papel=1469, id_usuario_alteracao=11977, id_localizacao=4, ds_nome_usuario_inclusao=NULL, ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2015-06-25 16:02:03.005', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1730882;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Intimação', id_processo=56046, id_usuario_inclusao=7868, id_usuario_exclusao=NULL, dt_inclusao='2015-09-15 17:08:56.929', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=60, id_processo_documento_bin=1747952, ds_observacao_procedimento=NULL, id_jbpm_task=7121002, in_documento_sigiloso=false, id_papel=1338, id_usuario_alteracao=7868, id_localizacao=9, ds_nome_usuario_inclusao='AEDA VALLE CAVALCANTE', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2015-09-15 17:09:30.830', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='AEDA VALLE CAVALCANTE', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1786292;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Despacho', id_processo=56046, id_usuario_inclusao=93794, id_usuario_exclusao=NULL, dt_inclusao='2016-03-15 12:06:37.845', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=63, id_processo_documento_bin=1855540, ds_observacao_procedimento=NULL, id_jbpm_task=8935837, in_documento_sigiloso=false, id_papel=1469, id_usuario_alteracao=11977, id_localizacao=4, ds_nome_usuario_inclusao=NULL, ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2016-03-17 14:45:38.271', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1903099;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Intimação de pauta', id_processo=56046, id_usuario_inclusao=86978, id_usuario_exclusao=NULL, dt_inclusao='2018-08-01 16:35:49.994', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=71, id_processo_documento_bin=3007333, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1338, id_usuario_alteracao=0, id_localizacao=9, ds_nome_usuario_inclusao='TAYNER PINTO DE SOUSA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-01 16:35:50.098', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='TAYNER PINTO DE SOUSA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3177716;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Intimação de pauta', id_processo=56046, id_usuario_inclusao=86978, id_usuario_exclusao=NULL, dt_inclusao='2018-08-08 20:29:12.740', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=71, id_processo_documento_bin=3021483, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5031, id_usuario_alteracao=0, id_localizacao=9, ds_nome_usuario_inclusao='TAYNER PINTO DE SOUSA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-08 20:29:12.771', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='TAYNER PINTO DE SOUSA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3192416;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão de julgamento', id_processo=56046, id_usuario_inclusao=7602, id_usuario_exclusao=NULL, dt_inclusao='2018-08-15 17:33:06.344', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=57, id_processo_documento_bin=3031070, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5031, id_usuario_alteracao=7602, id_localizacao=9, ds_nome_usuario_inclusao='MARIANA SILVA CAMPOS DUTRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='MARIANA SILVA CAMPOS DUTRA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2018-08-15 17:45:56.191', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-15 17:53:59.618', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='MARIANA SILVA CAMPOS DUTRA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3202385;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Acórdão', id_processo=56046, id_usuario_inclusao=126055, id_usuario_exclusao=NULL, dt_inclusao='2018-08-16 14:01:06.760', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=74, id_processo_documento_bin=3037374, ds_observacao_procedimento=NULL, id_jbpm_task=20463365, in_documento_sigiloso=false, id_papel=1469, id_usuario_alteracao=126055, id_localizacao=4, ds_nome_usuario_inclusao='JOÃO OTÁVIO DE NORONHA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-16 14:01:23.471', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='JOÃO OTÁVIO DE NORONHA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3208883;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Voto do Magistrado', id_processo=56046, id_usuario_inclusao=164538, id_usuario_exclusao=NULL, dt_inclusao='2018-06-25 18:04:36.418', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=72, id_processo_documento_bin=2897141, ds_observacao_procedimento=NULL, id_jbpm_task=20463365, in_documento_sigiloso=false, id_papel=1469, id_usuario_alteracao=126055, id_localizacao=4, ds_nome_usuario_inclusao='SERGIO RICARDO DE SOUZA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=3208883, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-16 14:01:23.481', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='SERGIO RICARDO DE SOUZA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3046624;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Relatório', id_processo=56046, id_usuario_inclusao=142052, id_usuario_exclusao=NULL, dt_inclusao='2018-05-28 17:12:01.438', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=73, id_processo_documento_bin=2678150, ds_observacao_procedimento=NULL, id_jbpm_task=20463365, in_documento_sigiloso=false, id_papel=1469, id_usuario_alteracao=126055, id_localizacao=4, ds_nome_usuario_inclusao='LUCIO GUIMARAES MARQUES', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=3208883, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-16 14:01:23.481', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='LUCIO GUIMARAES MARQUES', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=2816133;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Substabelecimento Azil Manoel Farias Jereissati', id_processo=56046, id_usuario_inclusao=189285, id_usuario_exclusao=NULL, dt_inclusao='2018-08-21 15:30:56.877', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=37, id_processo_documento_bin=3041264, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=189285, id_localizacao=57846, ds_nome_usuario_inclusao='ANDERSON DE SOUZA OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=3212811, nr_documento='', ds_instancia='2', dt_juntada='2018-08-21 15:34:10.785', in_lido=false, nr_ordem=2, id_instancia_origem=NULL, id_usuario_juntada=189285, ds_nome_usuario_juntada='ANDERSON DE SOUZA OLIVEIRA', ds_localizacao_usuario_juntada='ADVOGADO'
			WHERE id_processo_documento=3212814;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Substabelecimento Jules Michelet Pereira Queiroz e Silva', id_processo=56046, id_usuario_inclusao=189285, id_usuario_exclusao=NULL, dt_inclusao='2018-08-21 15:30:56.876', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=37, id_processo_documento_bin=3041263, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=189285, id_localizacao=57846, ds_nome_usuario_inclusao='ANDERSON DE SOUZA OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=3212811, nr_documento='', ds_instancia='2', dt_juntada='2018-08-21 15:34:10.761', in_lido=false, nr_ordem=1, id_instancia_origem=NULL, id_usuario_juntada=189285, ds_nome_usuario_juntada='ANDERSON DE SOUZA OLIVEIRA', ds_localizacao_usuario_juntada='ADVOGADO'
			WHERE id_processo_documento=3212813;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Petição', id_processo=56046, id_usuario_inclusao=189285, id_usuario_exclusao=NULL, dt_inclusao='2018-08-21 15:30:56.875', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=36, id_processo_documento_bin=3041261, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=189285, id_localizacao=57846, ds_nome_usuario_inclusao='ANDERSON DE SOUZA OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='ANDERSON DE SOUZA OLIVEIRA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-21 15:34:10.603', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=189285, ds_nome_usuario_juntada='ANDERSON DE SOUZA OLIVEIRA', ds_localizacao_usuario_juntada='ADVOGADO'
			WHERE id_processo_documento=3212811;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Inclusão de Advogados', id_processo=56046, id_usuario_inclusao=124970, id_usuario_exclusao=NULL, dt_inclusao='2018-08-23 13:52:20.877', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=57, id_processo_documento_bin=3042937, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=124970, id_localizacao=42, ds_nome_usuario_inclusao='PAULO HENRIQUE BATISTA DOS SANTOS', ds_nome_papel=NULL, ds_nome_usuario_alteracao='PAULO HENRIQUE BATISTA DOS SANTOS', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-23 13:52:58.706', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=124970, ds_nome_usuario_juntada='PAULO HENRIQUE BATISTA DOS SANTOS', ds_localizacao_usuario_juntada='CHEFE DE SETOR'
			WHERE id_processo_documento=3214525;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PROCURAÇÃO CNJ', id_processo=56046, id_usuario_inclusao=189285, id_usuario_exclusao=NULL, dt_inclusao='2018-08-22 15:53:46.874', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=37, id_processo_documento_bin=3042257, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=189285, id_localizacao=57846, ds_nome_usuario_inclusao='ANDERSON DE SOUZA OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=3213790, nr_documento='', ds_instancia='2', dt_juntada='2018-08-22 15:54:13.339', in_lido=false, nr_ordem=1, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='ANDERSON DE SOUZA OLIVEIRA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3213794;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Procuração', id_processo=56046, id_usuario_inclusao=189285, id_usuario_exclusao=NULL, dt_inclusao='2018-08-22 15:49:09.185', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=37, id_processo_documento_bin=3042253, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=189285, id_localizacao=57846, ds_nome_usuario_inclusao='ANDERSON DE SOUZA OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-22 15:54:13.339', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='ANDERSON DE SOUZA OLIVEIRA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3213790;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Portaria n. 6 - PAD', id_processo=56046, id_usuario_inclusao=124614, id_usuario_exclusao=NULL, dt_inclusao='2018-08-29 13:57:46.628', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=107, id_processo_documento_bin=3050148, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=124614, id_localizacao=36, ds_nome_usuario_inclusao='FABIANA ALVES CALAZANS', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=3222339, nr_documento='', ds_instancia='2', dt_juntada='2018-08-29 14:00:21.254', in_lido=false, nr_ordem=1, id_instancia_origem=NULL, id_usuario_juntada=124614, ds_nome_usuario_juntada='FABIANA ALVES CALAZANS', ds_localizacao_usuario_juntada='CHEFE DE SETOR'
			WHERE id_processo_documento=3222342;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Portaria 06, de 28 de agosto de 2018', id_processo=56046, id_usuario_inclusao=124614, id_usuario_exclusao=NULL, dt_inclusao='2018-08-29 13:57:46.627', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=57, id_processo_documento_bin=3050146, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=124614, id_localizacao=36, ds_nome_usuario_inclusao='FABIANA ALVES CALAZANS', ds_nome_papel=NULL, ds_nome_usuario_alteracao='FABIANA ALVES CALAZANS', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-29 14:00:21.254', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=124614, ds_nome_usuario_juntada='FABIANA ALVES CALAZANS', ds_localizacao_usuario_juntada='CHEFE DE SETOR'
			WHERE id_processo_documento=3222339;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Autuação do PAD 6919-05', id_processo=56046, id_usuario_inclusao=7883, id_usuario_exclusao=NULL, dt_inclusao='2018-08-29 15:58:35.669', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=57, id_processo_documento_bin=3050727, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=7883, id_localizacao=42, ds_nome_usuario_inclusao='DAVI ALVARENGA BALDUINO ALA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='DAVI ALVARENGA BALDUINO ALA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-29 15:59:50.413', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=7883, ds_nome_usuario_juntada='DAVI ALVARENGA BALDUINO ALA', ds_localizacao_usuario_juntada='CHEFE DE SETOR'
			WHERE id_processo_documento=3223094;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Intimação', id_processo=56046, id_usuario_inclusao=7868, id_usuario_exclusao=NULL, dt_inclusao='2018-08-30 17:38:26.522', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=60, id_processo_documento_bin=3037374, ds_observacao_procedimento=NULL, id_jbpm_task=20742941, in_documento_sigiloso=false, id_papel=1338, id_usuario_alteracao=7868, id_localizacao=9, ds_nome_usuario_inclusao='AEDA VALLE CAVALCANTE', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-30 17:38:48.678', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='AEDA VALLE CAVALCANTE', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3230959;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Relatório de Inspeção das Unidades Jurisdicionais e Procedimentos Disciplinares ', id_processo=56046, id_usuario_inclusao=7999, id_usuario_exclusao=NULL, dt_inclusao='2015-02-27 15:40:16.082', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1627377, ds_observacao_procedimento=NULL, id_jbpm_task=5047408, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7999, id_localizacao=41, ds_nome_usuario_inclusao=NULL, ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2015-02-27 15:40:16.082', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1644763, nr_documento='Traslado do Autos Inspeção TJCE (IDs 1630787/1630788) da INSP 5622-02 em cumprimento ao ID1630681 do mencionado processo.', ds_instancia='2', dt_juntada='2015-02-27 17:55:38.491', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1644818;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Intimação de pauta', id_processo=56046, id_usuario_inclusao=86978, id_usuario_exclusao=NULL, dt_inclusao='2018-06-20 12:25:15.288', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=71, id_processo_documento_bin=2854433, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5031, id_usuario_alteracao=0, id_localizacao=9, ds_nome_usuario_inclusao='TAYNER PINTO DE SOUSA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-06-20 12:25:15.373', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='TAYNER PINTO DE SOUSA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3001416;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='(15) Inf Fornecidas - DOC 02', id_processo=56046, id_usuario_inclusao=7999, id_usuario_exclusao=NULL, dt_inclusao='2014-10-23 16:26:39.287', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1595200, ds_observacao_procedimento=NULL, id_jbpm_task=4354444, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7999, id_localizacao=41, ds_nome_usuario_inclusao='FRANCK DA COSTA BRAGA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2014-10-23 16:26:39.287', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1571428, nr_documento='', ds_instancia='2', dt_juntada='2014-12-17 13:38:06.154', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FRANCK DA COSTA BRAGA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1610340;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão - Alteração do Assunto', id_processo=56046, id_usuario_inclusao=7873, id_usuario_exclusao=NULL, dt_inclusao='2015-02-09 16:11:29.953', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=57, id_processo_documento_bin=1616278, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=7873, id_localizacao=35, ds_nome_usuario_inclusao=NULL, ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2015-02-09 16:12:16.745', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1632990;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 03 - Prot 7005 Id 1408462 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.457', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550818, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.322', in_lido=false, nr_ordem=18, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562395;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc.01', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.469', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=37, id_processo_documento_bin=1876471, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.469', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:00.563', in_lido=false, nr_ordem=1, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925522;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Pedido de acesso aos autos', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-05-04 09:04:32.973', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=36, id_processo_documento_bin=1886077, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-05-04 09:04:32.973', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada=NULL, in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1935929;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Decisão (ID1630681) da INSP 5622-02', id_processo=56046, id_usuario_inclusao=7999, id_usuario_exclusao=NULL, dt_inclusao='2015-02-27 15:40:16.081', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=104, id_processo_documento_bin=1627376, ds_observacao_procedimento=NULL, id_jbpm_task=5047408, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7999, id_localizacao=41, ds_nome_usuario_inclusao=NULL, ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2015-02-27 15:40:16.081', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1644763, nr_documento='Traslado do (ID1630681) da INSP 5622-02, em cumprimento ao presente documento do mencionado process', ds_instancia='2', dt_juntada='2015-02-27 17:55:37.897', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1644817;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão ref. ao traslado de doctos., conforme ID 1630681 da Insp 0005622-02.2014', id_processo=56046, id_usuario_inclusao=96789, id_usuario_exclusao=NULL, dt_inclusao='2015-02-27 15:40:16.080', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=57, id_processo_documento_bin=1627324, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=96789, id_localizacao=16942, ds_nome_usuario_inclusao=NULL, ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2015-02-27 15:40:48.318', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1644763;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão de juntada', id_processo=56046, id_usuario_inclusao=11683, id_usuario_exclusao=NULL, dt_inclusao='2015-06-19 15:51:49.778', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=57, id_processo_documento_bin=1695881, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5881, id_usuario_alteracao=11683, id_localizacao=1883, ds_nome_usuario_inclusao='MARCO THULIO DOS SANTOS', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2015-06-19 15:51:49.778', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada=NULL, in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1727987;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc. 4.3', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.474', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1876516, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.474', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:01.770', in_lido=false, nr_ordem=6, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925567;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Acompanha Prot 49034', id_processo=56046, id_usuario_inclusao=8001, id_usuario_exclusao=NULL, dt_inclusao='2015-09-08 18:05:54.339', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1742586, ds_observacao_procedimento=NULL, id_jbpm_task=7028779, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=8001, id_localizacao=41, ds_nome_usuario_inclusao='CICERO HUGO SANTOS SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2015-09-08 18:05:54.339', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1780535, nr_documento='', ds_instancia='2', dt_juntada='2015-09-08 18:42:54.254', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='CICERO HUGO SANTOS SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1780583;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Entrevista-Presidente-TJ-15 - Acompanha o Protocolo 6457 Id 1420501 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.541', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551230, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.561', in_lido=false, nr_ordem=102, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562824;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Depoimento - Eliane Cristina Ribeiro - Parcial 1', id_processo=56046, id_usuario_inclusao=11683, id_usuario_exclusao=NULL, dt_inclusao='2015-06-19 14:26:42.855', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1695730, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5881, id_usuario_alteracao=11683, id_localizacao=1883, ds_nome_usuario_inclusao='MARCO THULIO DOS SANTOS', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2015-06-19 14:26:42.855', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1727823, nr_documento='', ds_instancia='2', dt_juntada='2015-06-19 15:11:47.640', in_lido=false, nr_ordem=2, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='MARCO THULIO DOS SANTOS', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1727829;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Preparar minuta', id_processo=56046, id_usuario_inclusao=142057, id_usuario_exclusao=NULL, dt_inclusao='2017-08-21 16:35:58.297', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=63, id_processo_documento_bin=2160160, ds_observacao_procedimento=NULL, id_jbpm_task=16851591, in_documento_sigiloso=false, id_papel=NULL, id_usuario_alteracao=142057, id_localizacao=34, ds_nome_usuario_inclusao=NULL, ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2017-11-30 17:05:40.728', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada=NULL, in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=2246938;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Petição inicial', id_processo=56046, id_usuario_inclusao=7883, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.439', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=12, id_processo_documento_bin=1548908, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=7883, id_localizacao=42, ds_nome_usuario_inclusao='DAVI ALVARENGA BALDUINO ALA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='DAVI ALVARENGA BALDUINO ALA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-10 14:53:23.436', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='DAVI ALVARENGA BALDUINO ALA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1560365;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Ofício', id_processo=56046, id_usuario_inclusao=168504, id_usuario_exclusao=NULL, dt_inclusao='2018-06-13 13:29:58.440', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=34, id_processo_documento_bin=2805142, ds_observacao_procedimento=NULL, id_jbpm_task=19491933, in_documento_sigiloso=false, id_papel=1469, id_usuario_alteracao=126055, id_localizacao=4, ds_nome_usuario_inclusao=NULL, ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2018-06-13 13:29:58.440', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-06-13 14:23:29.477', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=126055, ds_nome_usuario_juntada='JOÃO OTÁVIO DE NORONHA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=2946681;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Carta de Ordem nº 75 - 2015 SPR', id_processo=56046, id_usuario_inclusao=111961, id_usuario_exclusao=NULL, dt_inclusao='2016-04-04 17:43:22.334', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1866644, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1656, id_usuario_alteracao=111961, id_localizacao=21830, ds_nome_usuario_inclusao='ALEXANDRE SANTOS BEZERRA SA - Representação do TJCE', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-04 17:43:22.334', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1914939, nr_documento='', ds_instancia='2', dt_juntada='2016-04-04 17:48:32.735', in_lido=false, nr_ordem=1, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='ALEXANDRE SANTOS BEZERRA SA - Representação do TJCE', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1914944;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Informações', id_processo=56046, id_usuario_inclusao=111961, id_usuario_exclusao=NULL, dt_inclusao='2016-03-23 14:26:55.911', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=30, id_processo_documento_bin=1860740, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1656, id_usuario_alteracao=111961, id_localizacao=21830, ds_nome_usuario_inclusao='ALEXANDRE SANTOS BEZERRA SA - Representação do TJCE', ds_nome_papel=NULL, ds_nome_usuario_alteracao='ALEXANDRE SANTOS BEZERRA SA - Representação do TJCE', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2016-03-23 14:29:42.709', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='ALEXANDRE SANTOS BEZERRA SA - Representação do TJCE', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1908675;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Informações', id_processo=56046, id_usuario_inclusao=111961, id_usuario_exclusao=NULL, dt_inclusao='2016-04-04 17:43:22.333', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=30, id_processo_documento_bin=1866639, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1656, id_usuario_alteracao=111961, id_localizacao=21830, ds_nome_usuario_inclusao='ALEXANDRE SANTOS BEZERRA SA - Representação do TJCE', ds_nome_papel=NULL, ds_nome_usuario_alteracao='ALEXANDRE SANTOS BEZERRA SA - Representação do TJCE', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2016-04-04 17:48:32.735', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='ALEXANDRE SANTOS BEZERRA SA - Representação do TJCE', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1914939;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Contestação', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.468', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=19, id_processo_documento_bin=1876459, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='FLAVIO JACINTO DA SILVA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2016-04-18 16:53:00.376', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925510;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão ref. ao cadastro de advogado conforme Procuração (Id 1925522) do presente feito.', id_processo=56046, id_usuario_inclusao=122491, id_usuario_exclusao=NULL, dt_inclusao='2016-04-25 14:17:35.499', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=57, id_processo_documento_bin=1879509, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=122491, id_localizacao=25090, ds_nome_usuario_inclusao='SILVANIO PEREIRA DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='SILVANIO PEREIRA DA SILVA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2016-04-25 14:19:20.453', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='SILVANIO PEREIRA DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1928881;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Intimação', id_processo=56046, id_usuario_inclusao=99786, id_usuario_exclusao=NULL, dt_inclusao='2018-06-13 14:41:38.996', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=60, id_processo_documento_bin=2805142, ds_observacao_procedimento=NULL, id_jbpm_task=19496973, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=99786, id_localizacao=36, ds_nome_usuario_inclusao='ANDRESSA GOMES DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-06-13 14:42:00.487', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='ANDRESSA GOMES DE OLIVEIRA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=2946712;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc.03', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.471', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1876473, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.471', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:01.592', in_lido=false, nr_ordem=3, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925524;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc.05', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.477', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1876474, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.477', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:01.843', in_lido=false, nr_ordem=9, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925525;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc.06', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.478', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1876475, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.478', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:01.854', in_lido=false, nr_ordem=10, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925526;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc. 07', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.479', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1876478, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.479', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:01.871', in_lido=false, nr_ordem=11, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925529;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc. 4.1', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.472', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=103, id_processo_documento_bin=1876515, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.472', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:01.633', in_lido=false, nr_ordem=4, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925566;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc. 4.4', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.475', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1876517, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.475', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:01.793', in_lido=false, nr_ordem=7, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925568;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc. 4.5', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.476', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1876518, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.476', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:01.822', in_lido=false, nr_ordem=8, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925569;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc. 02', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.470', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1876521, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.470', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:01.578', in_lido=false, nr_ordem=2, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925572;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc. 4.2', id_processo=56046, id_usuario_inclusao=130210, id_usuario_exclusao=NULL, dt_inclusao='2016-04-18 16:18:01.473', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=103, id_processo_documento_bin=1876526, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=130210, id_localizacao=27527, ds_nome_usuario_inclusao='FLAVIO JACINTO DA SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao='2016-04-18 16:18:01.473', id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1925510, nr_documento='', ds_instancia='2', dt_juntada='2016-04-18 16:53:01.720', in_lido=false, nr_ordem=5, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='FLAVIO JACINTO DA SILVA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1925577;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Intimação de pauta', id_processo=56046, id_usuario_inclusao=86978, id_usuario_exclusao=NULL, dt_inclusao='2018-06-13 17:50:06.355', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=71, id_processo_documento_bin=2808733, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5031, id_usuario_alteracao=0, id_localizacao=9, ds_nome_usuario_inclusao='TAYNER PINTO DE SOUSA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-06-13 17:50:06.456', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='TAYNER PINTO DE SOUSA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=2951716;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Ofício nº 527 - 2018 GAPRE', id_processo=56046, id_usuario_inclusao=11982, id_usuario_exclusao=NULL, dt_inclusao='2018-06-15 17:39:00.508', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=30, id_processo_documento_bin=2828679, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1656, id_usuario_alteracao=11982, id_localizacao=154, ds_nome_usuario_inclusao='MARCELO ROSENO DE OLIVEIRA - Representação do TJCE', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=2973661, nr_documento='', ds_instancia='2', dt_juntada='2018-06-15 17:39:49.138', in_lido=false, nr_ordem=1, id_instancia_origem=NULL, id_usuario_juntada=11982, ds_nome_usuario_juntada='MARCELO ROSENO DE OLIVEIRA', ds_localizacao_usuario_juntada='REPRESENTAÇÃO DO TJCE - PROCURADOR/GESTOR'
			WHERE id_processo_documento=2973662;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Informações', id_processo=56046, id_usuario_inclusao=11982, id_usuario_exclusao=NULL, dt_inclusao='2018-06-15 17:39:00.507', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=30, id_processo_documento_bin=2828678, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1656, id_usuario_alteracao=11982, id_localizacao=154, ds_nome_usuario_inclusao='MARCELO ROSENO DE OLIVEIRA - Representação do TJCE', ds_nome_papel=NULL, ds_nome_usuario_alteracao='MARCELO ROSENO DE OLIVEIRA - Representação do TJCE', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-06-15 17:39:49.138', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=11982, ds_nome_usuario_juntada='MARCELO ROSENO DE OLIVEIRA', ds_localizacao_usuario_juntada='REPRESENTAÇÃO DO TJCE - PROCURADOR/GESTOR'
			WHERE id_processo_documento=2973661;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão de Autuação', id_processo=56046, id_usuario_inclusao=7883, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 15:05:01.529', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=57, id_processo_documento_bin=1548925, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=7883, id_localizacao=42, ds_nome_usuario_inclusao='DAVI ALVARENGA BALDUINO ALA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='DAVI ALVARENGA BALDUINO ALA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-10 15:06:01.932', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='DAVI ALVARENGA BALDUINO ALA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1560383;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Despacho proferido pela Ministra Fatima Nancy Andrighi (Id 1556670) da RD 2748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.440', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=104, id_processo_documento_bin=1550784, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:24.834', in_lido=false, nr_ordem=1, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562360;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='INICIAL - Id 1401835 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.441', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=106, id_processo_documento_bin=1550785, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.259', in_lido=false, nr_ordem=2, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562361;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='certidão - Id 1402020 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.442', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1550786, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.267', in_lido=false, nr_ordem=3, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562362;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Ofício 138 - Id 1402025 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.443', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=106, id_processo_documento_bin=1550787, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.270', in_lido=false, nr_ordem=4, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562363;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Notícia - Id 1402028 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.444', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1550790, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.275', in_lido=false, nr_ordem=5, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562367;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Notícia2 - Id 1402030 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.445', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1550791, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.280', in_lido=false, nr_ordem=6, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562368;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Despacho - Id 1402044 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.446', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1550793, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.282', in_lido=false, nr_ordem=7, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562370;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Despacho - Id 1402113 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.447', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1550794, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.287', in_lido=false, nr_ordem=8, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562371;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão digitalizada - Protocolo nº 6880 - Id 1403865 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.448', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1550795, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.292', in_lido=false, nr_ordem=9, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562372;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão Digitalizada - Protocolo 7005 - Id 1404805 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.449', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1550797, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.294', in_lido=false, nr_ordem=10, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562374;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão - Id 1405336 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.450', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1550801, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.297', in_lido=false, nr_ordem=11, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562378;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Documentação complementar -Id 1405337 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.451', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1550803, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.302', in_lido=false, nr_ordem=12, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562380;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Despacho - Juiz Auxiliar da Corregedoria Nacional de Justiça Friedman Anderson Wendpap - Prot 6880 d', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.452', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=104, id_processo_documento_bin=1550805, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.304', in_lido=false, nr_ordem=13, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562382;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='audio-vídeo Protocolo 6880 Id 1408103 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.453', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550812, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.307', in_lido=false, nr_ordem=14, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562389;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Despacho - Juiz Auxiliar da Corregedoria Nacional de Justiça Friedman Anderson Wendpap - Prot 7005 d', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.454', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=104, id_processo_documento_bin=1550813, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.310', in_lido=false, nr_ordem=15, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562390;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 01 - Prot 7005 Id 140845 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.455', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550815, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.315', in_lido=false, nr_ordem=16, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562392;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 02 - Prot 7005 Id 1408461 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.456', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550817, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.318', in_lido=false, nr_ordem=17, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562394;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 04 - Prot 7005 Id 1408463 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.458', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550823, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.327', in_lido=false, nr_ordem=19, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562400;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 05 - Prot 7005 Id 1408464 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.459', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550824, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.332', in_lido=false, nr_ordem=20, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562401;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento=' Vídeo 06 - Id 1408465 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.460', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550825, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.337', in_lido=false, nr_ordem=21, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562402;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 07 - Prot 7005 Id 1408467 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.461', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550830, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.341', in_lido=false, nr_ordem=22, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562407;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Audio 08 - Prot 7005 Id 1408539 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.462', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550831, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.344', in_lido=false, nr_ordem=23, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562408;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Audio 09 - Prot 7005 Id 1408540 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.463', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550832, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.347', in_lido=false, nr_ordem=24, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562409;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Audio 10 - Prot 7005 Id 1408541 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.464', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550833, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.349', in_lido=false, nr_ordem=25, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562410;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 11 - Prot 7005 Id 1408542 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.465', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550847, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.354', in_lido=false, nr_ordem=26, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562424;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 12 - Prot 7005 Id 1408543 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.466', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550848, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.356', in_lido=false, nr_ordem=27, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562425;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 13 - Prot 7005 Id 1408545 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.467', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550858, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.359', in_lido=false, nr_ordem=28, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562437;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 14 - Prot 7005 Id 1408549 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.468', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550859, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.362', in_lido=false, nr_ordem=29, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562438;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 15 - Prot 7005 Id 1408550 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.469', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550860, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.364', in_lido=false, nr_ordem=30, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562439;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 16 - Prot 7005 Id 1408558 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.470', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550861, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.366', in_lido=false, nr_ordem=31, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562440;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 17 - Prot 7005 Id 1408554 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.471', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550862, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.371', in_lido=false, nr_ordem=32, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562441;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 18 - Prot 7005 Id 1408560 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.472', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550869, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.374', in_lido=false, nr_ordem=33, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562450;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 19 - Prot 7005 Id 1408559 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.473', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550882, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.377', in_lido=false, nr_ordem=34, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562464;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 20- Prot 7005 Id 1408565 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.474', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550883, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.379', in_lido=false, nr_ordem=35, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562465;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 21 - Prot 7005 Id 1408562 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.475', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550884, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.382', in_lido=false, nr_ordem=36, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562466;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 22 - Prot 7005 Id 1408571 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.476', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550885, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.384', in_lido=false, nr_ordem=37, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562467;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 23 - Prot 7005 Id 1408569 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.477', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1550887, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.387', in_lido=false, nr_ordem=38, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562470;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 24 - Prot 7005 Id 1408574 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.478', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551021, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.389', in_lido=false, nr_ordem=39, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562609;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 25 - Prot 7005 Id 1408573 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.479', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551027, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.391', in_lido=false, nr_ordem=40, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562615;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Áudio 26 - Prot 7005 Id 1408510 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.480', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551028, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.397', in_lido=false, nr_ordem=41, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562616;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Áudio 27 - Prot 7005 Id 1408611 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.481', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551030, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.399', in_lido=false, nr_ordem=42, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562618;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Áudio 28 - Prot 7005 Id 1408615 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.482', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551031, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.402', in_lido=false, nr_ordem=43, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562619;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 29 - Prot 7005 Id 1408617 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.483', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551032, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.404', in_lido=false, nr_ordem=44, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562620;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 30- Prot 7005 Id 1408619 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.484', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551033, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.407', in_lido=false, nr_ordem=45, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562621;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 31- Prot 7005 Id 1408624 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.485', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551034, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.409', in_lido=false, nr_ordem=46, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562622;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 32- Prot 7005 Id 1408648 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.486', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551036, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.412', in_lido=false, nr_ordem=47, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562624;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo33- Prot 7005 Id 1408665 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.487', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551037, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.414', in_lido=false, nr_ordem=48, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562625;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 34- Prot 7005 Id 1408627 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.488', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551042, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.419', in_lido=false, nr_ordem=49, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562630;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 35- Prot 7005 Id 1408630 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.489', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551043, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.422', in_lido=false, nr_ordem=50, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562631;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 36- Prot 7005 Id 1408677 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.490', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551045, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.425', in_lido=false, nr_ordem=51, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562633;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 37- Prot 7005 Id 1408678 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.491', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551046, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.427', in_lido=false, nr_ordem=52, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562634;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 38- Prot 7005 Id 1408672 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.492', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551047, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.430', in_lido=false, nr_ordem=53, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562635;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 39- Prot 7005 Id 1408673 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.493', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551048, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.432', in_lido=false, nr_ordem=54, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562636;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 40- Prot 7005 Id 1408680 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.494', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551049, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.435', in_lido=false, nr_ordem=55, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562637;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Áudio 41 - PROT 7005 Id 1408694 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.495', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551050, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.437', in_lido=false, nr_ordem=56, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562638;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Áudio 42 - PROT 7005 Id 1408695 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.496', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551051, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.440', in_lido=false, nr_ordem=57, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562639;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 43- Prot 7005 Id 1408696 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.497', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551052, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.443', in_lido=false, nr_ordem=58, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562640;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 44- Prot 7005 Id 1408699 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.498', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551053, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.445', in_lido=false, nr_ordem=59, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562641;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Áudio 45 - PROT 7005 Id 1408880 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.499', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551054, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.448', in_lido=false, nr_ordem=60, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562642;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Áudio 46 - PROT 7005 Id 1408881 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.500', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551055, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.450', in_lido=false, nr_ordem=61, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562643;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 47- Prot 7005 Id 1408882 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.501', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551057, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.456', in_lido=false, nr_ordem=62, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562645;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 48- Prot 7005 Id 1409154 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.502', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551058, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.458', in_lido=false, nr_ordem=63, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562646;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 49 Prot 7005 Id 1409163 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.503', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551059, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.461', in_lido=false, nr_ordem=64, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562647;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 50 Prot 7005 Id 1409164 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.504', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551065, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.464', in_lido=false, nr_ordem=65, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562653;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 51 Prot 7005 Id 1409165 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.505', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551066, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.466', in_lido=false, nr_ordem=66, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562654;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 52 Prot 7005 Id 1409166 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.506', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551069, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.469', in_lido=false, nr_ordem=67, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562657;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 53 Prot 7005 Id 1409167 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.507', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551070, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.471', in_lido=false, nr_ordem=68, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562658;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 54 Prot 7005 Id 1409169 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.508', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551071, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.474', in_lido=false, nr_ordem=69, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562659;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 55 Prot 7005 Id 1409170 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.509', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551072, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.476', in_lido=false, nr_ordem=70, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562660;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 56 Prot 7005 Id 1409171 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.510', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551077, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.479', in_lido=false, nr_ordem=71, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562665;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 57 Prot 7005 Id 1409178 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.511', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551078, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.482', in_lido=false, nr_ordem=72, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562666;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 58 Prot 7005 Id 1409187 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.512', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551079, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.484', in_lido=false, nr_ordem=73, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562667;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 59 Prot 7005 Id 1409198 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.513', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551080, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.487', in_lido=false, nr_ordem=74, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562668;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 60 Prot 7005 Id 1409225 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.514', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551081, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.490', in_lido=false, nr_ordem=75, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562669;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 61 Prot 7005 Id 1409226 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.515', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551082, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.493', in_lido=false, nr_ordem=76, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562670;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 62 Prot 7005 Id 1409227 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.516', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551083, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.496', in_lido=false, nr_ordem=77, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562671;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 63 Prot 7005 Id 1409287 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.517', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551084, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.498', in_lido=false, nr_ordem=78, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562672;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 64 Prot 7005 Id 1409293 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.518', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551087, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.501', in_lido=false, nr_ordem=79, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562675;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 65 Prot 7005 Id 1409296 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.519', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551088, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.504', in_lido=false, nr_ordem=80, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562676;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 66 Prot 7005 Id 1409297 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.520', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551090, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.507', in_lido=false, nr_ordem=81, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562678;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 67 Prot 7005 Id 1409298 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.521', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551095, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.510', in_lido=false, nr_ordem=82, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562683;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 68 Prot 7005 Id 1409300 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.522', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551097, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.512', in_lido=false, nr_ordem=83, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562685;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 69 Prot 7005 Id 1409301 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.523', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551098, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.515', in_lido=false, nr_ordem=84, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562686;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 70 Prot 7005 Id 1409304 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.524', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551099, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.517', in_lido=false, nr_ordem=85, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562687;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 71 Prot 7005 Id 1409305 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.525', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551100, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.520', in_lido=false, nr_ordem=86, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562688;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 72 Prot 7005 Id 1409306 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.526', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551106, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.522', in_lido=false, nr_ordem=87, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562695;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 73 - Prot 7005 Id 1409308 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.527', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551107, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.525', in_lido=false, nr_ordem=88, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562696;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 74 - Prot 7005 Id 1409311 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.528', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551108, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.528', in_lido=false, nr_ordem=89, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562697;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 75 - Prot 7005 Id 1409313 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.529', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551109, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.530', in_lido=false, nr_ordem=90, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562698;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Vídeo 76 - Prot 7005 Id 1409315 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.530', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551110, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.533', in_lido=false, nr_ordem=91, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562699;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão Digitalizada - Protocolo nº 6250 Id 1412317 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.531', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551111, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.535', in_lido=false, nr_ordem=92, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562701;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='OFICIO Nº 138-2014-APG - MPCE - PROT 6250 Id 1419244 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.532', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=106, id_processo_documento_bin=1551114, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.538', in_lido=false, nr_ordem=93, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562704;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='ACOMPANHA PROT 6250 Id 1419246 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.533', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551119, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.540', in_lido=false, nr_ordem=94, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562709;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Intimação Id 1419304 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.534', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551125, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.543', in_lido=false, nr_ordem=95, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562715;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Intimação Id 1419305 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.535', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551126, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.545', in_lido=false, nr_ordem=96, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562716;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Despacho Id 1419359 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.536', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=104, id_processo_documento_bin=1551127, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.548', in_lido=false, nr_ordem=97, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562717;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Ato Ordinatório Id 1419446 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.537', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551129, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.551', in_lido=false, nr_ordem=98, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562719;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão-Despacho Id 1419447 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.538', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551132, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.553', in_lido=false, nr_ordem=99, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562722;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão digitalizada - Protocolo nº 6457 Id 1420301 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.539', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551133, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.556', in_lido=false, nr_ordem=100, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562723;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='OFICIO Nº 138 Id 1420470 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.540', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=106, id_processo_documento_bin=1551134, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.558', in_lido=false, nr_ordem=101, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562724;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Entrevista-Presidente-TJ-15 - Acompanha o Protocolo 6457 Id 1420502 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.542', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551231, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.563', in_lido=false, nr_ordem=103, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562825;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Entrevista-Presidente-TJ-15 - Acompanha o Protocolo 6457 Id 1420503 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.543', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551232, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.566', in_lido=false, nr_ordem=104, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562826;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão Digitalizada - Protocolo nº 6513 Id 1428504 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.544', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551240, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.569', in_lido=false, nr_ordem=105, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562835;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Certidão Digitalizada - Protocolo nº 6512 Id 1430005 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.545', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551241, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.571', in_lido=false, nr_ordem=106, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562836;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='MEMORANDO Nº 142-GP-2014 Id 1431645 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.546', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551242, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.574', in_lido=false, nr_ordem=107, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562837;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='OFICIO Nº 426-2014-CGMP-PGJ-CE - PROT 6513 Id 1431660 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.547', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=106, id_processo_documento_bin=1551243, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.576', in_lido=false, nr_ordem=108, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562838;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='OFICIO Nº 139-2014-APG - PROT 6458 - Acompanha o Memorando 142-GP-2014 Id 1431668 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.548', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551244, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.579', in_lido=false, nr_ordem=109, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562839;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Entrevista-Presidente-TJ-15 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.549', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551245, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.581', in_lido=false, nr_ordem=110, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562840;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='VÍDEO - Entrevista-Presidente-TJ-15 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.550', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551246, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.584', in_lido=false, nr_ordem=111, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562841;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='OFICIO Nº 427-2014-CGMP - MPCE - PROT 6512 Id 1432180 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.551', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=106, id_processo_documento_bin=1551247, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.586', in_lido=false, nr_ordem=112, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562843;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='ACOMPANHA PROT 6512 Id 1432200 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.552', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551248, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.589', in_lido=false, nr_ordem=113, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562844;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='SRO-PROCURADORIA GERAL DE JUSTIÇA NO ESTADO DO CEARÁ Id 1437258 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.553', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551249, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.591', in_lido=false, nr_ordem=114, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562845;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Informações Id 144 6186 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.554', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=105, id_processo_documento_bin=1551284, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.594', in_lido=false, nr_ordem=115, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562881;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Oficio nº 892 - 2014 GAPRE da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.555', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=106, id_processo_documento_bin=1551285, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.597', in_lido=false, nr_ordem=116, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562882;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc 01 Id 1446365 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.556', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551286, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.599', in_lido=false, nr_ordem=117, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562883;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc 02 Id 1446366 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.557', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551287, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.602', in_lido=false, nr_ordem=118, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562884;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc Id 1446367 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.558', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551290, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.604', in_lido=false, nr_ordem=119, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562887;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc Id 1446368 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.559', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551291, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.607', in_lido=false, nr_ordem=120, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562888;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc Id 1446369 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.560', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551292, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.610', in_lido=false, nr_ordem=121, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562889;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc Id 1446370 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.561', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551293, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.613', in_lido=false, nr_ordem=122, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562890;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc Id 1446371 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.562', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551294, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.616', in_lido=false, nr_ordem=123, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562891;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc Id 1446372 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.563', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551296, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.619', in_lido=false, nr_ordem=124, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562893;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc Id 1446373 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.564', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551297, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.622', in_lido=false, nr_ordem=125, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562894;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Doc Id 1446374 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.565', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551298, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.624', in_lido=false, nr_ordem=126, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562895;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 Abr por adv Id 1446302 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.566', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551300, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.627', in_lido=false, nr_ordem=127, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562898;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 agost por adv Id 1446303 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.567', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551301, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.630', in_lido=false, nr_ordem=128, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562899;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 agost Id 1446305 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.568', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551302, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.632', in_lido=false, nr_ordem=129, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562900;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 abril Id 1446306 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.569', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551303, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.635', in_lido=false, nr_ordem=130, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562901;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 dez por adv Id 1446310 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.570', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551304, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.637', in_lido=false, nr_ordem=131, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562902;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 dez Id 1446311 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.571', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551305, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.640', in_lido=false, nr_ordem=132, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562903;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 jul por adv Id 1446314 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.572', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551306, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.642', in_lido=false, nr_ordem=133, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562904;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 jul Id 1446315 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.573', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551307, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.645', in_lido=false, nr_ordem=134, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562905;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 jun por adv Id 1446318 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.574', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551312, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.647', in_lido=false, nr_ordem=135, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562911;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 jun Id 1446320 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.575', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551313, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.650', in_lido=false, nr_ordem=136, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562912;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 mai Id 1446322 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.576', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551314, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.652', in_lido=false, nr_ordem=137, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562913;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011mai por adv Id 1446324 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.577', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551315, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.655', in_lido=false, nr_ordem=138, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562914;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 nov por adv Id 1446325 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.578', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551316, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.658', in_lido=false, nr_ordem=139, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562915;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 nov Id 1446326 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.579', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551318, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.660', in_lido=false, nr_ordem=140, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562918;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 out por adv Id 1446329 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.580', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551319, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.663', in_lido=false, nr_ordem=141, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562919;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 out Id 1446330 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.581', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551321, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.665', in_lido=false, nr_ordem=142, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562922;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 set por adv Id 1446333 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.582', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551322, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.668', in_lido=false, nr_ordem=143, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562923;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 set Id 1446335 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.583', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551323, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.670', in_lido=false, nr_ordem=144, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562924;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATISTICA 2011 Id 1446337 da RD 0002748-44', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.584', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551324, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.673', in_lido=false, nr_ordem=145, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562925;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='PLANTÃO JUDICIÁRIO ESTATÍSTICA 2012 jan Id 1446338 da RD 0002748-44 ', id_processo=56046, id_usuario_inclusao=7896, id_usuario_exclusao=NULL, dt_inclusao='2014-10-10 14:51:07.585', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=1551325, ds_observacao_procedimento=NULL, id_jbpm_task=3589218, in_documento_sigiloso=false, id_papel=1427, id_usuario_alteracao=7995, id_localizacao=41, ds_nome_usuario_inclusao='CELIA REGINA LIMA DE OLIVEIRA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='IRANEIDE PEREIRA DE ALMEIDA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=1560365, nr_documento=NULL, ds_instancia='2', dt_juntada='2014-10-20 13:49:25.675', in_lido=false, nr_ordem=146, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada='IRANEIDE PEREIRA DE ALMEIDA', ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=1562926;

			SELECT * FROM TB_PROCESSO_DOCUMENTO WHERE ID_PROCESSO = 108252;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Ato', id_processo=108252, id_usuario_inclusao=7883, id_usuario_exclusao=NULL, dt_inclusao='2018-08-29 15:56:31.749', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=12, id_processo_documento_bin=3050724, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=7883, id_localizacao=42, ds_nome_usuario_inclusao='DAVI ALVARENGA BALDUINO ALA', ds_nome_papel=NULL, ds_nome_usuario_alteracao='DAVI ALVARENGA BALDUINO ALA', ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada='2018-08-29 15:57:37.910', in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=7883, ds_nome_usuario_juntada='DAVI ALVARENGA BALDUINO ALA', ds_localizacao_usuario_juntada='CHEFE DE SETOR'
			WHERE id_processo_documento=3223091;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Portaria nº 6 - PAD, de 28 de agosto de 2018', id_processo=108252, id_usuario_inclusao=7883, id_usuario_exclusao=NULL, dt_inclusao='2018-08-29 15:56:31.750', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=107, id_processo_documento_bin=3050725, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=5879, id_usuario_alteracao=7883, id_localizacao=42, ds_nome_usuario_inclusao='DAVI ALVARENGA BALDUINO ALA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=3223091, nr_documento='', ds_instancia='2', dt_juntada='2018-08-29 15:57:37.910', in_lido=false, nr_ordem=1, id_instancia_origem=NULL, id_usuario_juntada=7883, ds_nome_usuario_juntada='DAVI ALVARENGA BALDUINO ALA', ds_localizacao_usuario_juntada='CHEFE DE SETOR'
			WHERE id_processo_documento=3223092;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Habilitação em processo', id_processo=108252, id_usuario_inclusao=166499, id_usuario_exclusao=NULL, dt_inclusao='2018-08-31 10:12:30.147', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=36, id_processo_documento_bin=3058966, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=NULL, id_localizacao=44460, ds_nome_usuario_inclusao='JULES MICHELET PEREIRA QUEIROZ E SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=NULL, nr_documento=NULL, ds_instancia='2', dt_juntada=NULL, in_lido=false, nr_ordem=NULL, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3231349;
			UPDATE core.tb_processo_documento
			SET ds_processo_documento='Inclusão de Advogados', id_processo=108252, id_usuario_inclusao=166499, id_usuario_exclusao=NULL, dt_inclusao='2018-08-31 10:14:49.660', dt_exclusao=NULL, ds_motivo_exclusao=NULL, in_ativo=true, id_tipo_processo_documento=53, id_processo_documento_bin=3058970, ds_observacao_procedimento=NULL, id_jbpm_task=NULL, in_documento_sigiloso=false, id_papel=1005, id_usuario_alteracao=NULL, id_localizacao=44460, ds_nome_usuario_inclusao='JULES MICHELET PEREIRA QUEIROZ E SILVA', ds_nome_papel=NULL, ds_nome_usuario_alteracao=NULL, ds_nome_usuario_exclusao=NULL, ds_nome_localizacao=NULL, dt_alteracao=NULL, id_pk_tb_processo_documento_pg=NULL, id_sessao_pg=NULL, id_documento_principal=3231349, nr_documento='', ds_instancia='2', dt_juntada=NULL, in_lido=false, nr_ordem=1, id_instancia_origem=NULL, id_usuario_juntada=NULL, ds_nome_usuario_juntada=NULL, ds_localizacao_usuario_juntada=NULL
			WHERE id_processo_documento=3231353;

		### SCRIPT DE CORRECAO

			BEGIN TRANSACTION ;
			  INSERT INTO CORE.TB_PROCESSO_DOCUMENTO 
			    SELECT NEXTVAL('CORE.SQ_TB_PROCESSO_DOCUMENTO'),
			           DS_PROCESSO_DOCUMENTO,
			           (SELECT ID_PROCESSO FROM CORE.TB_PROCESSO WHERE  NR_PROCESSO ILIKE '%0006919-05.2018.2.00.0000%'), -- PROCESSO DE DESTINO    
			           ID_USUARIO_INCLUSAO,
			           ID_USUARIO_EXCLUSAO,
			           DT_INCLUSAO,
			           DT_EXCLUSAO,
			           DS_MOTIVO_EXCLUSAO,
			           IN_ATIVO,
			           ID_TIPO_PROCESSO_DOCUMENTO,
			           ID_PROCESSO_DOCUMENTO_BIN,
			           DS_OBSERVACAO_PROCEDIMENTO,
			           ID_JBPM_TASK,
			           IN_DOCUMENTO_SIGILOSO,
			           ID_PAPEL,
			           ID_USUARIO_ALTERACAO,
			           ID_LOCALIZACAO,
			           DS_NOME_USUARIO_INCLUSAO,
			           DS_NOME_PAPEL,
			           DS_NOME_USUARIO_ALTERACAO,
			           DS_NOME_USUARIO_EXCLUSAO, 
			           DS_NOME_LOCALIZACAO, DT_ALTERACAO, 
			           ID_PK_TB_PROCESSO_DOCUMENTO_PG,
			           ID_SESSAO_PG,
			           ID_DOCUMENTO_PRINCIPAL,
			           NR_DOCUMENTO,
			           DS_INSTANCIA,
			           DT_JUNTADA,
			           IN_LIDO,
			           NR_ORDEM,
			           ID_INSTANCIA_ORIGEM  
			        FROM CORE.TB_PROCESSO_DOCUMENTO 
			        WHERE ID_PROCESSO = (SELECT ID_PROCESSO FROM CORE.TB_PROCESSO WHERE NR_PROCESSO ILIKE '%0006014-39.2014.2.00.0000%'); -- PROCESSO DE ORIGEM
			COMMIT TRANSACTION;

			SELECT * FROM CORE.TB_PROCESSO WHERE NR_PROCESSO ILIKE '%0006014-39.2014.2.00.0000%';
			SELECT * FROM CORE.TB_PROCESSO WHERE  NR_PROCESSO ILIKE '%0006919-05.2018.2.00.0000%';

			SELECT COUNT(*) FROM CORE.TB_PROCESSO_DOCUMENTO WHERE ID_PROCESSO = 56046;
			SELECT COUNT(*) FROM CORE.TB_PROCESSO_DOCUMENTO WHERE ID_PROCESSO = 108252;


	### [DEMANDA-0000] <LINK>

		### OBJETIVO
			> RETIRAR APTIDAO DE UM PROCESSO

		### SCRIPT DE ANALISE

					/**
			Boa tarde,
			Solicito que retirem os processos abaixo relacionados do "aptos para inclusão em pauta", pois estão com erro no andamento (o gabinete não consegue retirar, pois é um erro do sistema):

			RD 4530-86 - Corregedoria
			RD 941-18 - Corregedoria
			Insp 4762-59 - Corregedoria

			PP 7229-45 - Corregedoria
			RD 4943-31 - Corregedoria
			PP 4626-96 - Corregedoria

			RD 5652-37 - Corregedoria
			PCA 4733-77 - Representante do MPU
			Consulta 1370-24 - Fernando de Mattos

			Atenciosamente,

			Andressa Oliveira
			Chefe da Seção de Apoio ao Plenário
			Secretaria Processual
			Conselho Nacional de Justiça
			SEPN QUADRA 514 NORTE - LOTE 7, BLOCO D, SALA 201
			70760-544 - Brasília
			: +55 61 2326-5228 
			*/

			-- CONSULTAR PROCESSOS
			SELECT CONCAT(ID_PROCESSO || ' ' || ', ') AS RESULTADO
			FROM TB_PROCESSO
			WHERE NR_PROCESSO ILIKE '%4530-86%'
			OR NR_PROCESSO ILIKE '%941-18%'
			OR NR_PROCESSO ILIKE '%4762-59%'
			OR NR_PROCESSO ILIKE '%7229-45%'
			OR NR_PROCESSO ILIKE '%4943-31%'
			OR NR_PROCESSO ILIKE '%4626-96%'
			OR NR_PROCESSO ILIKE '%5652-37%'
			OR NR_PROCESSO ILIKE '%4733-77%'
			OR NR_PROCESSO ILIKE '%1370-24%';

			SELECT * FROM TB_PROCESSO WHERE NR_PROCESSO ILIKE '%4530-86%';

			SELECT DISTINCT PROCESSO.NR_PROCESSO, PROCESSO.NR_PROCESSO, SESSAO.ID_SESSAO, SESSAO.DS_APELIDO, SESSAO.DT_SESSAO
			FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF PAUTA, CORE.TB_PROCESSO PROCESSO, CLIENT.TB_SESSAO SESSAO
			WHERE PAUTA.ID_SESSAO = SESSAO.ID_SESSAO
			AND PAUTA.ID_PROCESSO_TRF = PROCESSO.ID_PROCESSO
			AND PAUTA.ID_PROCESSO_TRF IN(53192)
			ORDER BY SESSAO.DT_SESSAO DESC;

			BEGIN;
				UPDATE CLIENT.TB_PROCESSO_TRF SET IN_SELECIONADO_PAUTA = FALSE, IN_PAUTA_VIRTUAL = NULL
				WHERE ID_PROCESSO_TRF IN( 53192 )
				AND IN_SELECIONADO_PAUTA = TRUE;
			COMMIT;

			SELECT * FROM CLIENT.TB_SESSAO WHERE ID_SESSAO = 504;

			-- VERIFICAR EM QUAIS SESSOES ESTAO DETERMINADOS PROCESSOS
			SELECT DISTINCT PROCESSO.NR_PROCESSO, PROCESSO.NR_PROCESSO, SESSAO.ID_SESSAO, SESSAO.DS_APELIDO, SESSAO.DT_SESSAO
			FROM CLIENT.TB_SESSAO_PAUTA_PROC_TRF PAUTA, CORE.TB_PROCESSO PROCESSO, CLIENT.TB_SESSAO SESSAO
			WHERE PAUTA.ID_SESSAO = SESSAO.ID_SESSAO
			AND PAUTA.ID_PROCESSO_TRF = PROCESSO.ID_PROCESSO
			AND PAUTA.ID_PROCESSO_TRF IN( 53192, 78684, 79045, 72605, 93940, 55293, 89941, 105291, 42864 )
			ORDER BY SESSAO.DT_SESSAO DESC;

			SELECT ID_PROCESSO_TRF, B.NR_PROCESSO
			FROM TB_PROCESSO_TRF A
			INNER JOIN TB_PROCESSO B 
			ON A.ID_PROCESSO_TRF = B.ID_PROCESSO
			WHERE ID_PROCESSO_TRF IN( 53192, 78684, 79045, 72605, 93940, 55293, 89941, 105291, 42864 )
			AND IN_SELECIONADO_PAUTA <> FALSE;

			BEGIN;
				-- UPDATE CLIENT.TB_PROCESSO_TRF SET IN_SELECIONADO_PAUTA = FALSE, IN_PAUTA_VIRTUAL = NULL
				WHERE ID_PROCESSO_TRF IN( 53192, 78684, 79045, 72605, 93940, 55293, 89941, 105291, 42864 )
				AND IN_SELECIONADO_PAUTA = TRUE;
			COMMIT;

			-- BACKUP
			SELECT * 
			FROM TB_PROCESSO_TRF 
			WHERE ID_PROCESSO_TRF IN( 53192 );

			UPDATE client.tb_processo_trf
			SET nr_sequencia=4530, nr_digito_verificador=86, nr_ano=2014, nr_identificacao_orgao_justica=200, id_jurisdicao=2, in_inicial='I', cd_processo_status='D', vl_causa=0.00, dt_autuacao='2014-07-30 15:34:13.892', nr_origem_processo=0, in_segredo_justica=false, ds_observacao_segredo=NULL, in_justica_gratuita=false, id_classe_judicial=1311, id_orgao_julgador=3, dt_transitado_julgado=NULL, id_localizacao_inicial=42, id_estrutura_inicial=11, in_apreciado_segredo='N', dt_distribuicao='2014-07-30 15:34:14.010', in_apreciado_sigilo='N', in_selecionado_pauta=false, in_revisado=false, id_orgao_julgador_revisor=NULL, id_pessoa_marcou_revisado=NULL, id_pessoa_marcou_pauta=NULL, id_cargo=2, in_outra_instancia=false, id_endereco_wsdl=NULL, id_orgao_julgador_colegiado=2, id_proc_referencia=NULL, ds_proc_referencia=NULL, in_selecionado_julgamento=false, id_pessoa_marcou_julgamento=NULL, id_cl_judicial_outra_instancia=NULL, nr_instancia='2', id_pessoa_relator_processo=NULL, in_apreciado_justica_gratuita=false, id_pes_apreciou_jus_gratuita=NULL, dt_sugestao_sessao=NULL, in_pronto_revisao=NULL, in_tutela_liminar=false, in_apreciado_tutela_liminar=NULL, id_sessao_sugerida=NULL, id_municipio_fato_principal=NULL, vl_peso_processual=2.00, vl_peso_distribuicao=200.00, id_orgao_julgador_cargo=15, in_violacao_faixa_valores=NULL, in_incidente=false, in_mandado_devolvido=false, in_deve_marcar_audiencia=false, id_competencia=4, ds_objeto='CorOrd nº 3769-55.2014 - TJMS - Procedimento instaurado de ofício durante a Correição - Apuração - Penhora - Sistema BACENJUD - Valor Elevado', dt_solicitacao_inclusao_pauta='2017-05-29 18:51:27.632', in_pauta_virtual=NULL, dt_vinculacao_relator=NULL, dt_vinculacao_revisor=NULL, in_exige_revisor=false, tp_composicao_julgamento=NULL
			WHERE id_processo_trf=53192;

		### SCRIPT DE CORRECAO

			BEGIN TRANSACTION;
				UPDATE CLIENT.TB_PROCESSO_TRF SET IN_SELECIONADO_PAUTA = FALSE, IN_PAUTA_VIRTUAL = NULL
				WHERE ID_PROCESSO_TRF IN( 53192, 78684, 79045, 72605, 93940, 55293, 89941, 105291, 42864 )
				AND IN_SELECIONADO_PAUTA = TRUE;
			COMMIT TRANSACTION;

	### [BASIS-58334 - PC-1449] <https://sgo.basis.com.br/browse/BASIS-58334 - http://www.cnj.jus.br/jira/browse/PC-1449>

		### OBJETIVO
			# REALIZAR CHERRY-PICK PARA A DEMANDA (BASIS-58334 - PC-1449)

				> git fetch origin
				> git checkout 2.0.0.7_cnj 
				> git cherry-pick a56d72c561e1280371a1254f7b3da47f2f9fe748 	
				> git push origin 2.0.0.7_cnj

	### [BASIS-59276 - PC-1465] <https://sgo.basis.com.br/browse/BASIS-59276 - http://www.cnj.jus.br/jira/browse/PC-1465>

		### OBJETIVO
			> ALTERAR HORARIO DA SESSOA NAS MOVIMENTACOES E NOS DOCUMENTOS DE INTIMACAO PARA TODOS OS PROCESSOS
			> ERRO:     O SISTEMA ESTA PEGANDO A DATA DA TABELA "TB_SALA_HORARIO" E NAO A DATA SETADA NO CADASTRAMENTO DA SESSAO

		### SCRIPT DE ANALISE

			# SESSAO VIRTUAL  = 503
			# SESSAO PLENARIA = 498

			-- 
			SELECT
			    NSPNAME,
			    RELNAME,
			    ATTNAME
			   
			SELECT *    
			FROM
			    PG_NAMESPACE N,
			    PG_CLASS C,
			    PG_ATTRIBUTE A,
			    PG_TYPE T
			WHERE
			    N.OID = C.RELNAMESPACE
			    AND C.RELKIND ILIKE 'R'
			    AND A.ATTNUM > 0
			    AND NOT A.ATTISDROPPED
			    AND A.ATTRELID = C.OID
			    AND A.ATTTYPID = T.OID
			    AND C.RELNAME ILIKE '%TB_PROCESSO_DOCUMENTO_BIN%'
			ORDER BY
			    NSPNAME,
			    RELNAME,
			    ATTNAME;
			    
			SELECT * FROM TB_SESSAO WHERE ID_SESSAO IN(498,503);

			SELECT * 
			FROM TB_SESSAO A
			INNER JOIN CLIENT.TB_SALA_HORARIO B
			ON B.ID_SALA_HORARIO = A.ID_SALA_HORARIO
			WHERE ID_SESSAO IN(498,503);

			SELECT * FROM TB_USUARIO_LOGIN WHERE ID_USUARIO = 7870;

			-- LOCALIZAR TODOS OS PROCESSOS DE UMA SESSAO       
			SELECT * FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO IN(503);

			SELECT *
			FROM CORE.TB_PROCESSO_EVENTO
			WHERE DS_TEXTO_FINAL_EXTERNO ILIKE 'Incluído em pauta para 11/10/2018 00:00:00 Plenário virtual. ';

			SELECT ID_EVENTO, DS_MOVIMENTO FROM TB_EVENTO WHERE DS_MOVIMENTO ILIKE '%PAUTA%'; -- 264 Incluído em pauta para #{data_hora} #{local}.

			-- RECUPERA PROCESSOS EM UMA DETERMINADA SESSAO
			SELECT B.ID_PROCESSO
			FROM TB_EVENTO A
			INNER JOIN CORE.TB_PROCESSO_EVENTO B
			ON B.ID_EVENTO = A.ID_EVENTO
			WHERE A.ID_EVENTO = 264 
			AND B.ID_PROCESSO IN(SELECT ID_PROCESSO_TRF FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO IN(503))
			AND (TO_CHAR(B.DT_ATUALIZACAO::DATE, 'YYYY-MM-DD') = '2018-10-03');

			-- RECUPERAR TEXTO DOS MOVIMENTOS
			SELECT B.ID_PROCESSO_EVENTO, E.ID_PROCESSO, D.ID_PROCESSO_DOCUMENTO_BIN, E.NR_PROCESSO, B.DS_TEXTO_FINAL_EXTERNO, B.DS_TEXTO_FINAL_INTERNO

			SELECT *
			FROM TB_EVENTO A
			INNER JOIN CORE.TB_PROCESSO_EVENTO B
			ON B.ID_EVENTO = A.ID_EVENTO
			INNER JOIN CORE.TB_PROCESSO_DOCUMENTO C
			ON C.ID_PROCESSO_DOCUMENTO = B.ID_PROCESSO_EVENTO
			INNER JOIN CORE.TB_PROCESSO_DOCUMENTO_BIN D
			ON D.ID_PROCESSO_DOCUMENTO_BIN = C.ID_PROCESSO_DOCUMENTO_BIN
			INNER JOIN CORE.TB_PROCESSO E
			ON E.ID_PROCESSO = B.ID_PROCESSO
			WHERE A.ID_EVENTO = 264 
			AND B.ID_PROCESSO IN(SELECT ID_PROCESSO_TRF FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO IN(503))
			AND (TO_CHAR(B.DT_ATUALIZACAO::DATE, 'YYYY-MM-DD') = '2018-10-03');

			-- RECUPERAR 'PROCESSO DOCUMENTO BIN' PARA A ALTERACAO DOS DOCUMENTOS
			SELECT ID_PROCESSO_DOCUMENTO, ID_PROCESSO_DOCUMENTO_BIN
			FROM TB_PROCESSO_DOCUMENTO
			WHERE ID_PROCESSO IN( 94680,108844,93423,75926,77207,97287,66490,102511,104771,100686,63887,86628,102968,109284,107371,101536,102182,86481,103082,66871,75354,104436,102481,102893,96847,89249,83191,78578,103685,102206,72319,89202,100806,98373,66649,96871)
			AND (TO_CHAR(DT_INCLUSAO::TIMESTAMP, 'YYYY-MM-DD') = '2018-10-03');

			SELECT *
			FROM CORE.TB_PROCESSO_DOCUMENTO_BIN
			WHERE ID_PROCESSO_DOCUMENTO_BIN IN(3105933,3105983,3106033,3106183,3106233,3106333,3106383,3106433,3106483,3106533,3106583,3106633,3106683,3106733,3106783,3106833,3106883,3106933,3106983,3107033,3107083,3107133,3107183,3107233,3107283,3107333);
			/*
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002495-85.2016.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='88162dbf1fc93f24141620ab7d2107de', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:17.852', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='j0Y4EHAzrHcnSL9Bq5HSUXhnECcxsw62TGQtI42AqKAPZ0pCUYWt1eUNYXFzYk8vRKqPmF/rwRtg
			gOw6sxpyz3B9m9FcRYoLIoJFzwt5EXNlXBSTUIfN2+ok2+08QnuDvP4CiiIj+I/q99oYuwviL2hw
			N8vxJpKNxaK5dHIx/tWjPW9PXO0tfBsxYRk5OZkGpA3eL/E8Gymltc8vcxJYhndneqcol5aXDTiR
			wp6IO0xJw+sP3hpe7/UNBRNuR8ZKVwDzrEOvejB1UsrF8mKgLUALUokQNHZFu1WeCbq6TT0QzK93
			Zm7tRKnOxh6P9i2zk+4dSn4sFB8TMJL0KPMewZMqegb2AFBQaOZ23HBAmHYthlNMCZD65pBgt5dd
			7pVfLsplnazNt8RAJKQOvNFCiu28ZwId4rCdQqnUxpHOis1oucuquo52Kt0gVqklTqpSGp9hFDJQ
			TFlhohnFK86XdENZrSx7Z3CquSYevI8r4LHz37HNoLYnJiV4rN9N3glqjJQYkflVPmw7Tlj4mpGa
			K9U/9MDHJZJl+kROXxQhqFv1T2Avwv5r//qQisxCknTyBZBYuExkLG7Z5UrRcPQOEGEMASIWTAY7
			37Mf33ah9zcmDY53qygCbATNzVyqceYnvsOGZNR3EmHRhvyeuC0Pea8go51+cEUM8L4HEpqIEXk=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:23.718', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='3dacb808dfce114bb3494e4ba0762afe0543134f'
			WHERE id_processo_documento_bin=3105933;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002685-82.2015.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='1b4d75fb0070b9f4408e84c9f9045e45', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:24.224', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='GVusdnN6W2s/h7iUz2Y7TQv6NYJSwkCoBG3V4tlIe+Ui+KMyeCJiK5vTifrMG0yUrtawjiH57llC
			dulNfMkJfXADyZDU5IVWUisShp37oE2kE0XlYORpIlc1ZfxbCJM9UYeWxg1XLRWkG4TV5BU69h6p
			wJsJm93sI3yxaPsFIqqRlZkM5ov6M0ZOThelXAYlJelYgcmFS+4CJq8fG5w/umZabb1V1C2P9w7+
			osCMdlc8qsAiTmv2u8yzVDuxhshALRoYC0hRi5psu9a2OmeZep78SazoVmr2anYIKqADZjFW2eIs
			HSAL/8KBFC24MwytjE263HQdruZ5/9tIfXpuSU06AnAcasYvfNcUD12I+0IMDBlCrfR0HnFkH8is
			dA9N4+egzVMKMbov1r3A+ixZvFe4ly28q507+dshq/m6YabjFJboIqwHAXGtol8fxH2DFRbmAQrp
			4DnQlNhBeEv2LY653jZu02Dnqu23mxjksermSlHWYN7fOYh2hfzLcHlbdCWB4TZUNrXFVcM2s1NA
			+1D3kIDBpUlqGz0cXRQADUnnyeM1fxkRyLhvSD14cjyt9IO4/jf9pcClfXOEfG47409s+6Ww51vL
			pdB9r9QmQdnSSBrxeRYw6f/xV65tbloJzW8s8Y7qAekOQboay1MiBCd3/0XhAk2j2XRpfcFBw6M=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:24.255', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='d3d69d63f6f3bbea9443733a77d6dc09a9954866'
			WHERE id_processo_documento_bin=3105983;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002799-84.2016.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='c24330ee52e3d9dd1c3f1acc97f3e7a5', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:24.763', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='J0bW208UaaIh5MG6zZSuKV/blw355H39FqnR1mWcOjTu3XjPr0Da+6jdpKpx8LZf11gGIxva15Yc
			CKyRh/hnQkVtzmGA6vNWqXZAIr25ABdCZ5nFYMiWgE0iuYv7EWhSXRiGJ36JCtD+bpLw3Z7kAvlO
			K7ENuw5fU6iffHu6AikuZx/dtrwfbd3neAOILHo0uIDoSCaKRcpCmVFBh34UgWhelg7vZpBsaHj/
			9iTd5zdk9c0kkJnee7Vi7chHSXo4q5T272JkiGb4XeCmV53Tf7AQtOqCz8XqKLEbu/dSxj7jf+J1
			HnVitMkW4bWOEH7ZfOgz3/O64pSfU9axf7PwhiR9wORt8bUVsYZUOXWF3CTmPgqUnK2627R12452
			Pue89A2ezyVJFcRJfcgznLkL7z7QGPJULHJySjM6QgIL+3iLvzh1kP/NUhdJWblxpDKm6nxlEEiJ
			+cD0QCMagERXRgvd/xdFhS0MLQgOshy8hD2QEb6I2fohCXyanGx56TgTi6ZdRQBmhMTevbxETFyX
			zebr6q/8TfZNWCorGNDr0or6wKXNr3LbHdkAfyGPDOhkUE3N1Wp+2I6Mop1cgXdUCiyqp6me/uW0
			0sJ5yJ2T4Rwu46xzi5O8rjUHkVdnCzQTkMmMRZI4/Zb2p9urF66FfU5v8eTlUUj8TTQrb+1EuJg=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:24.779', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='73f1df800e42256371be92ba92420e1bea7aabc3'
			WHERE id_processo_documento_bin=3106033;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0007432-70.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='bac4a29bac41b466089cccc702a2af5a', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:26.659', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='KqfUtUjTQO0hwU/q/YDlTYW7WFD+75tj8ohOx36USTx47n1W/SK7REy/ja1S6+tFXx1Kk7R2xZ3w
			dvsP+2n4cYQravY2vv+tRI+mOsTi6AfRxF9EbNeOwKLhfGWxRgPaHEXl3b4lAK1u/0fLvQq3/McM
			5VBrU4BF11fDhAev4A0Brn62RXOqXSFi/nG14tiNH80o4DwL2bgm8kn99jZcqSW9lk7BJii0ygVZ
			B858MA+0ZPWxjdvx/fZ6dO7O5LWN8kgKRV3QdD9gwGlIknPuNZAUR7OQG9zVyK46RqpJPtoU+ncs
			b+1hvFjzObYTdhoZyy8CbuIDIPP+9xba2tIXgHjWUxGuA40OaigN/keVfRCuEnLEMIA7dM5+puEw
			WBsJ8R5TekFvbm03uORbBzIaO6sBjpjhZ6fzefreyV4Npv2AgW/rR076Ei+rQoXST9Ubb2UNaY2y
			9S/EkP2YNWduqepZ+xypIIco3p9Lo0VVsrVnhf8paCavFeZpg4Mprf6OS73yPu4WUS09Pevs8apt
			E27PQQxP6bGkrS+HHq9ekYyA+XQV92tehGCch/Pwb5kkU8UBP4gjs3lNYHMfRzrG+ODQHjHPNTkm
			csVnNtiWUxu7Q6Zt3xqyylMQX3q5E8+Z2HNo/MRU/3vWY+6+OMDfD59RYA7gU3ViEXJiMKodCGw=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:26.859', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='260a1214283defdaffe6d661958dd78c793ca8c3'
			WHERE id_processo_documento_bin=3106183;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0004146-84.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='bcbb90c4c3e1b9a90e428b0a7fbea6fb', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:27.441', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='L2G2UgERqIx+OHckHgSIYKrskcmZOkU00S+L+Kbf9yhm3gC2svPs9oS9oz/93cKg+q/z3u9OTwrZ
			EFbaDPDEMgfpiRqaVi96AtE8yUUYUoW37OvH9N0pT0wGQ3UW62Cv4SVBR1YwKKhlE/jRQrNTjXEW
			ynxmJ0qMqujOoc+7YMMYLVVjZ1frz754qw6/o9Mk5Sop+hEwttr2ATcIWgnOHQbVjk4z6y6V7WgK
			pB3VSVz3eXsKDGA07Nx/vI11pU0R2dXDKbfgSbk1aMBzVdZvVthBSeoqp5TDVzdPxiNx+z5E4yp2
			dh79PStVXe6H9ORLN+RwZtg44wrnFMKIb5ex1NQwoNuivDmkDV6aIibDin+n6ek87zl48cn84Ip8
			MlMMU0UKkBU7W7odeXbkOmmF2PLNcR3x0MT2dCnT40fV4tfJ+PoZIy0XUpolkzhOMJcm2g48Oobt
			lC4jck1/AU8iRKkEL3I7gxBviSJhnjHPe9c6obvnl3oiPpT//EIliA7OJ1ZChWkaZ81BqE+coJWo
			8eLPDiY2T9AxkJBkC+hY/IgXENtVQ5VIO1R1ptu35t+Xxr0unnvHvczGdnVEnXS9nKwtq1egDMgE
			fmyHz8RQvK6E3JY7nAyFPrkgHHVb2j5XiMInoo1mIikx2fKy7J0JPnucaQ2Supm18TtMomYy5w8=', ds_cert_chain='MIIGFDCCBhAwggP4AgEBMA0GCSqGSIb3DQEBBAUAMIHnMSUwIwYDVQQKExxDb25zZWxobyBOYWNpb25hbCBkZSBKdXN0aWNhMTEwLwYDVQQLEyhEZXBhcnRhbWVudG8gZGUgVGVjbm9sb2dpYSBkYSBJbmZvcm1hY2FvMR0wGwYJKoZIhvcNAQkBFg5kdGlAY25qLmp1cy5icjERMA8GA1UEBxMIQnJhc2lsaWExGTAXBgNVBAgTEERpc3RyaXRvIEZlZGVyYWwxCzAJBgNVBAYTAkJSMTEwLwYDVQQDEyhDb25zZWxobyBOYWNpb25hbCBkZSBKdXN0aWNhIEludGVybmFsIENBMB4XDTEyMDgwNzIyNTIzNloXDTEzMDgwNzIyNTIzNlowgbMxCzAJBgNVBAYTAkJSMRkwFwYDVQQIExBEaXN0cml0byBGZWRlcmFsMSUwIwYDVQQKExxDb25zZWxobyBOYWNpb25hbCBkZSBKdXN0aWNhMTEwLwYDVQQLEyhEZXBhcnRhbWVudG8gZGUgVGVjbm9sb2dpYSBkYSBJbmZvcm1hY2FvMS8wLQYDVQQDEyZQcm9jZXNzbyBKdWRpY2lhbCBFbGV0cm9uaWNvIFBKZSAxLjQuMzCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKvP/EWgWsbVqLwSRYUwlftebsHunimNfozkTYQ0KF5HnT0talve+uXYls213nuYgA14PBV19EZzwWL0Xp4llApNUW5K3kL264VswNymwjFe0DFxTWXtVK30qgN8WkKb044NHoWXZB9AU54QHChmo1z4qk2PN6VjOBXfsAjB2s3mFKlSVMymye48h4ox5ZJdlBmBOC1/3C4zf2LO+gL24RAF3WGEKtnoUXPfvV3IpG1ibO7t+guwmbDROzh3Zt2XL4Rbg+9q+f3pDMZJhvcviMQocG/ZpqZ5dcKWJGcG2TGawDY1BnlCzp6USmmjIigMJXDdf1Zq1vpTCevtMuWExUNHaBGdd6WrRna53GVPrenExX46EuZ7jRwAL24BMCLOYYZFGd9LMF4N7KPmTpnWNrXffdVFVGIHx/xcBspCFn+zAWPGvRXeM2saNnrzPnu3CZzdWEiUK1i+VQ+ypmGiqeLRpS9WeVuRld7SlmriDHigehYOQiDK4YSExoqDELYoalbikRBJbBTSr2CyVVU0AjhmOMCrgee2vjcKiYPX8efVqLxmiqbIXotMR/lzHImNpspwQmugqhIOgeY3UkZ3pX4Ekh4fKUvwTaUfBETf9AsV/aq8HcapMzKAyN/izS7N3G2zGeoGzVMCChiO3UnZR3y/MGD+n+rmCnnMnwGGa0lZAgMBAAEwDQYJKoZIhvcNAQEEBQADggIBAK5DLLIzwTBJteTTcOog8xmYW9aEjRTWuncDigtdrYqR17vl6LS9Anycm4YKYsiKzPYWz7YlXkiKJdz/3T0eXXZxYZi3PbsAPB8gW2EH4zezBhOvueX9hF8CcE6LDt7kkVrLoBF3uyKbhzqof/K2LlmeY4Ofdo0FgwhIsOcTT9L/gSfvI7mt3d1zoT+Mu3LwF/yLBdFDGlSb+gDPf2RWWegPmZee0UCSiz1I/nrNNlMm+SXJl7PSlT6X9mf7IdIP4nzQXFWA/nN9aiyc4sl0ES7jOtwptnv7r9WXVDOK7w37mf1i4r84b0rAjRNzojqMLYR0NlZNUywhAYQp2zXjWjAfgC8QLll+fHofytphnfmGxkYknI9yctMp//30Psz900MkAJudulGzlT0MCVhLvUhrlgxEhnpn6e99Zk12qkkRj4OwBjDfLztowXyuoVHxNzCU/2z+uv/TBkqXzqiDfXog6srcwcyZJ6CRtjkqGjFW1b8w7vMnT1UyMdXEfIXLAvq+TJtAKG+73ez7/0aLQY2C+kgs7hg5Cjvwl2O3E77nmdRlEKPQcUZIwjLXk20p7WEtj8lvitcJ3Vib0z7noqMSKChL1pTCEaQ+qaScLmcnADH3uaujuM4VaWqkpj32QrNd9CaHjFvxbf28imkYxikstEbSGLjhtppxRf2mohhJ', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:27.487', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='19f8e20d35abfc8ae3a17e2d7c29190716487d7c'
			WHERE id_processo_documento_bin=3106233;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002146-14.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='544870c587888be3c1ef23845c632846', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:28.507', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='FcpINKiBL7J2pxl7+S4F8vRFdoN4t7owmuO+suVzzWBXq8S0hPpo7fZE7ZNp1YAPlSbrKgIR5wGv
			a/Q4hay07D6Yug+VyjPboiePC02BfUx0BHsCCWdnu/LKGwq5fTRZhFry6QlCHU5lMkJlfLgWC97F
			fdT08uqYhh4dSdD39H4RH989e9z0TU2YwuQXSgMk1oKfgAwDxqidj1to+xbZ6EHUsGjHKEaqAAG7
			tdwux8p0O7sOkw0H2qhNgFkaU4G++qYMuaoMQYgfQcFDVaegQhks1YDi1e9sYaMgAlSN3Y04Gv0y
			yZL4wRPP/2yllIgSYIwCWV5/TkRA4amAPQqRdFsHwYWE0e/QF6maVsyOr4gMCzUXc+m8lMZ3Esin
			iKG5bpr/CJlwxN599l1J1UEWlsDDP12e9hIepIsl+D4NyiPYIrixyJrdJvV55xO9OGsNfyeKaaPh
			qdSv+GErWMcTlQhC7dqabJcmn5ETwTsk549vmneiwT7Qzen7qRFvmVeRJoYAYQRXZEyBvLtkerLB
			okXK9yae3NV8LsU8oXId1v54juPBdbv5qXwtuz8MevnHj/8cnys5wCCsf/AcE6/XFiMLaAsLrAkW
			NjLpSgDGP2eftcZVI2K+6BJKQ2Sx3uWjEeGgGVsDZRhc8oTw/iQ4maTBJVQlTQbmLsZCBuHqBU0=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:28.523', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='61cb3021500112d4edcd1d5a41fd46b4bb4a1011'
			WHERE id_processo_documento_bin=3106333;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002798-31.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='197564ea7c79c4d80162078f5a228290', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:28.993', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='nePe+euQ8dcLlrClPmk28tB7eCVPdrKTdD3Fs6jemZbfEek5x2pQvMll87S7cB5Rbg9lntbVtmNm
			wIb1E3MmkMoxbCjaRlQEceKzGXXTKqnOixdP7ICgPdvSFxiip+Jf1ksk0u8nwBJ4YShkV/t/Me/e
			coI2Q62nc5lxce274d4vxGAUhP3QSNQ3QPQ33p329+715mKlsAkYxU8fta1Mjiq9gn1a25hl/hMe
			hc9nPCTAazaRvMnOecg4kQ/VuSup2kMCzVxk/aWE2JCBtwWT1dxdaAG0We/KUf4LJ1jo4F8BMw/v
			TWUxjpjHJfYaW75I/1iRKtWy+mnNV3RHQFBVE8JXu56AUHUHnd/e5jS/VL48aUkyHyn6xyslsbou
			hPPAX0LWXqpXNvq6mQ9nrgnzBIDartf3Z7GPCHFh3K3M10Q4DCq9Fl9pdmG2KFoRC0vRjiDUVGTq
			bM07lDfxol/eU7k9o1zUC4gjd53sbw3NiZZtS1DMqi2vVmWsi4lwz44WrcfmaY6b1tfAStVRLbVP
			nw7ezlmkxp5P0wgfbKuHF6Z3/xBDciH6ybLsiZNgM0196WGl+QIvvitJ8M/ehMRi+fOrZ628SSy4
			YSPa8Ie55C53oxISjhWgtGaMDmCImapVA6+6qCZm+S5vgl8Sho94kKy8ZVMNE0KPEpKDawn/ccc=', ds_cert_chain='MIIGFDCCBhAwggP4AgEBMA0GCSqGSIb3DQEBBAUAMIHnMSUwIwYDVQQKExxDb25zZWxobyBOYWNpb25hbCBkZSBKdXN0aWNhMTEwLwYDVQQLEyhEZXBhcnRhbWVudG8gZGUgVGVjbm9sb2dpYSBkYSBJbmZvcm1hY2FvMR0wGwYJKoZIhvcNAQkBFg5kdGlAY25qLmp1cy5icjERMA8GA1UEBxMIQnJhc2lsaWExGTAXBgNVBAgTEERpc3RyaXRvIEZlZGVyYWwxCzAJBgNVBAYTAkJSMTEwLwYDVQQDEyhDb25zZWxobyBOYWNpb25hbCBkZSBKdXN0aWNhIEludGVybmFsIENBMB4XDTEyMDgwNzIyNTIzNloXDTEzMDgwNzIyNTIzNlowgbMxCzAJBgNVBAYTAkJSMRkwFwYDVQQIExBEaXN0cml0byBGZWRlcmFsMSUwIwYDVQQKExxDb25zZWxobyBOYWNpb25hbCBkZSBKdXN0aWNhMTEwLwYDVQQLEyhEZXBhcnRhbWVudG8gZGUgVGVjbm9sb2dpYSBkYSBJbmZvcm1hY2FvMS8wLQYDVQQDEyZQcm9jZXNzbyBKdWRpY2lhbCBFbGV0cm9uaWNvIFBKZSAxLjQuMzCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKvP/EWgWsbVqLwSRYUwlftebsHunimNfozkTYQ0KF5HnT0talve+uXYls213nuYgA14PBV19EZzwWL0Xp4llApNUW5K3kL264VswNymwjFe0DFxTWXtVK30qgN8WkKb044NHoWXZB9AU54QHChmo1z4qk2PN6VjOBXfsAjB2s3mFKlSVMymye48h4ox5ZJdlBmBOC1/3C4zf2LO+gL24RAF3WGEKtnoUXPfvV3IpG1ibO7t+guwmbDROzh3Zt2XL4Rbg+9q+f3pDMZJhvcviMQocG/ZpqZ5dcKWJGcG2TGawDY1BnlCzp6USmmjIigMJXDdf1Zq1vpTCevtMuWExUNHaBGdd6WrRna53GVPrenExX46EuZ7jRwAL24BMCLOYYZFGd9LMF4N7KPmTpnWNrXffdVFVGIHx/xcBspCFn+zAWPGvRXeM2saNnrzPnu3CZzdWEiUK1i+VQ+ypmGiqeLRpS9WeVuRld7SlmriDHigehYOQiDK4YSExoqDELYoalbikRBJbBTSr2CyVVU0AjhmOMCrgee2vjcKiYPX8efVqLxmiqbIXotMR/lzHImNpspwQmugqhIOgeY3UkZ3pX4Ekh4fKUvwTaUfBETf9AsV/aq8HcapMzKAyN/izS7N3G2zGeoGzVMCChiO3UnZR3y/MGD+n+rmCnnMnwGGa0lZAgMBAAEwDQYJKoZIhvcNAQEEBQADggIBAK5DLLIzwTBJteTTcOog8xmYW9aEjRTWuncDigtdrYqR17vl6LS9Anycm4YKYsiKzPYWz7YlXkiKJdz/3T0eXXZxYZi3PbsAPB8gW2EH4zezBhOvueX9hF8CcE6LDt7kkVrLoBF3uyKbhzqof/K2LlmeY4Ofdo0FgwhIsOcTT9L/gSfvI7mt3d1zoT+Mu3LwF/yLBdFDGlSb+gDPf2RWWegPmZee0UCSiz1I/nrNNlMm+SXJl7PSlT6X9mf7IdIP4nzQXFWA/nN9aiyc4sl0ES7jOtwptnv7r9WXVDOK7w37mf1i4r84b0rAjRNzojqMLYR0NlZNUywhAYQp2zXjWjAfgC8QLll+fHofytphnfmGxkYknI9yctMp//30Psz900MkAJudulGzlT0MCVhLvUhrlgxEhnpn6e99Zk12qkkRj4OwBjDfLztowXyuoVHxNzCU/2z+uv/TBkqXzqiDfXog6srcwcyZJ6CRtjkqGjFW1b8w7vMnT1UyMdXEfIXLAvq+TJtAKG+73ez7/0aLQY2C+kgs7hg5Cjvwl2O3E77nmdRlEKPQcUZIwjLXk20p7WEtj8lvitcJ3Vib0z7noqMSKChL1pTCEaQ+qaScLmcnADH3uaujuM4VaWqkpj32QrNd9CaHjFvxbf28imkYxikstEbSGLjhtppxRf2mohhJ', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:29.040', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='e9aee79b739172c2be9df735270c0c1719539d68'
			WHERE id_processo_documento_bin=3106383;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0003059-93.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='63cdfd317d6995daa13272c8b0583e5b', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:29.711', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='gnL4Z5MDX3RozeOmR7OUPG0dXAJeLGNhOIJDIYCX3Ei+B4rdsLay+00GcVVzqetjTTfLiBBCfV2b
			/Q/+MV7fPSehobsOJjwOnC3dyXb9pEYYbpRocupPAFdieO4PX1GT5Vj54w4TFRV9o3MfDP1lCEk/
			Z3q5buzjwzlK9Uu8L3xo8ZsTxZcc7I9xoT0qeHTzRPkwfOG+Rx2/Szc/sjeoPuWmcrua09E6/wZc
			qnoVZGKHEBG1YaO5tdQhGhQxwCfAyYdL3/85pyyVQQERoa5rbekfJAyV7LCai0/3HPpLcp8T01uu
			84fDW+zw9Zn8dCWk0Vp1MdwdyxtPl4gooortva0oCAl2mODaOtjDLc/kCAJZ4g/dxaQf9iT3MXXN
			TryDYjvh2KxR5baP3xsKJlbyG1BsUU2jLyWlPgT6F9BWEm5oAUNSSf/xDmP7l1vOHACvIOf2X2a3
			WXHr+FdDs9eChPygIyEfJoVui6WnamYPKQDDsDM9gMxkZ2M0STlSzyYGZt0VZIiN5fdx0p7mlI3X
			TR13nF7KZQCE6JGQzI63Hkd164vHDZai3EOR7JG2Z/AmRPUCbPIVUnsm3ZfR/VkC5hmWDdBurAxK
			9EIk9v760RtyJBkKy13IW6YvAAsV/uh72/qeWV1rJR4QhQ+R92EjzBbihewIOjyyfAyJi4GiEzE=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:29.726', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='f57bc67cd0bf3207a5a4e6ddbbc8913ede89e727'
			WHERE id_processo_documento_bin=3106433;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002603-46.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='d71af8575e93664db33e06e3b326915d', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:30.210', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='nMpe8wOlgCLSCrhRqhZMo0tL1B+VcWCtGzK/wXkwWX9umnj4RJRsb1ambmkiJeqv1xAI5c7qm1x4
			PSEQ6FVfhafxsudqzdVZN0JHl0jYo1NWsOmWB4mu0GyikpcwCBs6ZA85bCt8+E2+BHmR78ohNVkQ
			xSXLRnfeNrKWWhzoaGq8NSJ5GmxB/BKmCOwNNRCgV2mAFusSHDgu8tOAtJWuTUBwIuw/Fi67Bfya
			1KXpNoopPbD0lSNzr+IlubFAWn3QV2jEfBeHRMTGin5/Sl1VUEipcmC8NE1Yrbk2O2O2RLEfMhOD
			9EoID9uF2kP/YTjgB7eAS6KXFeYC2rdD1Vx5hjee86cf82Vq35q6+wcDmi22bG8j5fMcPgNNsAzb
			22IIVhlSUdwgf0q9YbOBlY6/0a4X5S/MKq+szqRPMPgmMZZ+h79hlkNJjN83ZswlX8dBkCB19nlX
			HMEVVJM+IoxpRZpaBWeE6ZgMo5+rkntvN4rqA/5+4JJYdmey2asYPZ6iIuWieRhwnpPV0bT7/cNE
			iwGWfUm6VBjV4Fw/+y1pt2j70ags+X277mneR6SeYntA6DyziZQfHdCrpgU5CtHakZkLsfMlTwfk
			zvMMve8GftyECyZyeTVF6ULTwpK1/iQohY2g30lDNb9XO3m6raF5bsaeVZhZ4PcvUs7dWCVg9M0=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:30.288', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='33472c16aa674391799b602b6cae7145972499ec'
			WHERE id_processo_documento_bin=3106483;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0006268-70.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='c2d77ba047dba46389415feb19670af8', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:32.488', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='gf4fq7U2D0ivb8Pea/6Nn6QMmhp4utbtPt5c8CtKdpc8cP8IhZSMvSTmg7qfsTddDb7P36s0TNEO
			pQHNAwNj0+bx6gBOpnu28zwRKnuE8RiNj/UHNnXUsEO3y1wHIAA4eiQlG2wY45rIyU0T5NTUwApD
			F8RbHVo95mJUFGxpIXaI9ebeiJcKVBrAvUN3ULYZkrVsowPQNLRxZ7mxl6jAdFQStyRaDulqmMuw
			SGqX2excmWKxrpmlsfgV3nkQ1V7CO9VpTBSxVyO2Ebfg2tYbcBcbqxceQW5cB1tIwJr5IN7lK7zJ
			QbuDr4tPna5M1eJnIxavou+ciS5LEsqp4SkQlYnEw/wjnCbL9JYrcISzRTf6Wqr3Jpx6XsXXIpCG
			ZDwglRRDJ2IEyZ7h5W2+zw+qFX/A90t69IUaWeztBMlmz0fwSJmav5sshxxMObP4rwjVf0eYIcKB
			YAWDxCViXSwCLi7bb6rIjHQ5z2FOijcQ7Y948/k+r+r/sNhJ0qCDwh6a9siPKI+gMBpKT39BKSky
			yMdLNqtTfqr7f1aU47r8gXjsuiyF/OIeAW3NMqIQibhotByUHX+I2kFg1uQ3EiM0PaPXCj4VSgc1
			YwfecBMd6zomjLUHqoj5rqJ4Vt+hCktUvoSD8h6OFIyEBIatGoa9P/bEyb163/FWmwDHc+fMVjQ=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:32.504', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='54cac14d2d39a035a47ee03b20d3caf669b96cc3'
			WHERE id_processo_documento_bin=3106533;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0003147-34.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='4b327862ec4056bca40682e51a051399', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:32.998', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='S7Ywqr7WvnmgSsy+4225wOuyNpSO7VqsdZq/AUjNnJvOmimAeh3cKvpur4yg/IYnRrXOvx+jq3j6
			v9Y5VdkWokCajg5yEzROGIqQFTJD4gUZkFuMINiFeQvT/oH6QvdQpWUnLKK2G3xr4w2ucyBdOeCF
			3IFYjrGPpXj7cX8X9LEps5qnxE+AZksnRVo8IwWv+KD3BrBffcNfdz86SiV2Gn5Y1EkWrJO+mAcF
			ga846P6JievWaGA9NxL3PoNsJ6lDTLu3AcnD8GPzwOwKmbw0lWvEUQFXyDSfdFjbhwp1420kgRwe
			lCOlt/a39+XQ3NOO6A8wKolXng+FPYrBpjDnNAdOT5QUny5s8FcOO+Y4ZK/eGIJJ6ROcBUiZ9ggm
			egGE8G31gzxHShSbiAsaztyPJvg9RNYqscyp3WeVS5LjDJIS17AgLz+jqPXMnO2kQpH7aWL12DT9
			IQZrRI+MN/pzLALHOB7b0Wq8PSM/Ez92xRFxGeh2OyiORpdErQo+/p04Y4wH5bceUsw5oJ++zqqt
			rixuj5busrJm27I1B+q3IYLCua+Hb5G/wSj1Bw4Apm8qvcjpsyq1VDONj1PvIpfubuKAyMaWQmuc
			FoourHg0hsB+KmniBj6ddrc9gCeQ3/Pf1346aee8p/bn7z8tEb3vxQn2McXpqQ2LpxPtPTBQd8s=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:33.060', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='a510aa3fa8a5548005dea7d7d70ce2b97773d2e9'
			WHERE id_processo_documento_bin=3106583;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002804-38.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='c0bbe42e4c3f89ad2d7bf391b128093f', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:33.602', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='mxpHvxdo7/UEkIFgyLcoal7Hy1OpjrEnoFOWYXdxAbTE5wrP0AKeaLumwbFGY03OfmjX/Ei4usB/
			9f8hEqvMl0ZxxNDglSP/8IIm1DdL6tt6B2EKvx/CLcHBs2zTc79J1nlGcm9ddY7n99vXcjrue/ej
			kJrEOz/i1U7gptjjk1mN7F1YM1fK3/iT2o3eXEWFhnr/4Lt73mKsm7Kup4EwvebVR9geVQ6lbKlc
			bd6Cx0YQaI2JXBa1dSvGsg7MILPgIfD6ZczvIhr2ETY65kBfrZBj3C52F4cOegGKBDwGfUid+aSf
			DkHM4/VWPLYpIG1WOKGhU8tUs/14e7YSRGExLUCcFne4kSXiozM4dFP+gUfeLJabDrdncVVdtQWi
			94erozLlAKcvNmncf9z6f/vAeF9hMvSjq6GXaV7p2t8tQ/UV3N6jo+rtGxxjdaAOJCSslcWyBx2P
			mikEiWYMY+3nERkkG106qjQFrWA5h8ODliAGwTUbu0yHnzUdtwlxpBPV8vd0n76SqwBpnOUBDNLK
			nNflEUITvZSq8jNaceWq/xbMvdj+gFrB0Fa2n++6TXDXrSbGdFE3wcEDzSg8DuW07VlxtWm9tDpL
			MUGBRaXpK94aq8Isz57HRb37ypC5IR0NVVN9AbD9pYrRsyeYoP6M046Pq60BtKXlzs9eAr4W0NM=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:33.617', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='419f4d432320971fa29a682775eee682d9422bb3'
			WHERE id_processo_documento_bin=3106633;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0004369-37.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='d44a98bea85624e2d928330522b0c901', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:34.105', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='f2OuuChzKz6hCmlDDzSsIXVaV0xqz+Pf6pLFWFlzgcDQmfQsTL6rxylw2Hw+MzbaqNhJiJJTr6TZ
			+glKvOa6wN+0SFLl2D2bcTAudkQQKtj4P7eoVlvTEm78uEF+mlY1z4KMj/gf1fJwIp9HY52nWwMo
			1cKl/s8N8T1Lhmu2yCyiLPp4EzvvwiW6Xv9dU27jv/mvhR0tjiRk7URalili+alzNPZ+k+cpjq0Z
			V0JWxzg2WkgmxIgcQB2ywMy4w73i0fe3NJTbkg2YgGam1IAcBYR+DJCiG5V1dCKoWWk9kHQUSz1D
			DQ/0vN8b3rS28WbrT2ZuOOwaD4HqK5cKDFwzKzg/26P65YTqj5ctAbL+zFOb3B/W1XKbXobSXIfd
			qMqwbggxNT4aj2kn6jG9tP9znhouJqM8x4rXFCCupM7Y5LD327U5Cs105fWAXuD+4tU2g9stGmgn
			xAeYUAz4ODR200//vvHZWLMZKSxvaZeoEoff35tfrDB06AUeuKVNrgQVLZso/MzQZIvGMiyY4kHn
			uZEA9TofU1HgNyvI7CtW//Lzjl1w41KXY/dPAZtYan9WsW4UAmFdk9pGMOmO49UAH9XXYalO5Frh
			RVgt+batqQRI34+Z+AVWqMPJ4hZhovFolKPi+7ZEX/DtRLLF4gY/VgOC9gNmyWu+yFgOHq2++KU=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:34.121', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='1fba2bb19e1bece53fc680d2bebfb35ab36d7525'
			WHERE id_processo_documento_bin=3106683;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0000860-98.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='6843bfa397427a75129b8b9e0ca7bee6', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:34.525', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='NRSEYKO4gW7yC2pupPc1f/68WPX7ZWjsqrXOVrGEd8t3ECvAmk6Ksk9Wx8i2fiXlWS7aQi6Z7TvD
			7nW1UuYb9ub+8Q6Fr56GAF3k6kURBiZW+sFk9wqfD52fmLAKjHHKlUWBs/6FZOg/C5Y6idt7c/CL
			QP9Nbfi12HnQOABrHigO0O15Z6oHYXyzmRKONIDd+bTkK+HlYpjQlOFWgmP9St6Kg5OFuiupHL7w
			lV6bejYUtOdqjTDm5nrJ1fldLN5Vg1aXAS/WtizwOT9B7dsRkDUDHeO8YA6ygXrbKO4wYzH8gG8z
			foq881S097AWR+8bVvN5n0ULstJS/uItUzoEXNnA87DJAXh/0wZTPJfHFnDlBatKtD0ayBP3lqOc
			lTnlpgkm9xa1jIu6X0GxuAOlVks67rS8Ej9y2NPe/mpRXyuFNrHyVzJoT+epqCEu7vo0arOFWq6M
			D0jeF1sObfKOLeqoaYcKe56Tb1jOzOjJ6ckrB6Z1jhZNU5t9cfIa5xZws8aeI8djw3YREXjaBBN/
			iYPNAzaffAPNV18yiZS6QNxvV3E77LHSkZEs77eKCSTovBouWi7eC+Vg5emonmzC9IJ/LMAVoS/w
			Nytt0w5CmWTnrB7K8kYjZ7xRppEb4nLRNq0bOvGgkjDvoI7rKPycFLwJDJHPnYhIbytjrGdnibA=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:34.571', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='8c793f8648aa43010aeef2f5dbb9a018c459bffb'
			WHERE id_processo_documento_bin=3106733;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0004149-73.2017.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='a88eae0a1fe8596536ae110a91382fa2', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:35.013', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='mhF6NhtFWUmZ3mQQx+vE9XGguxvkalRqWjHI5aU6Kv8336zoV3le212bb+K/HZoPVFpb8oKHICYq
			2IOvs9lvCMCm/xIZ1oQaFyer3WcAiwJbw5GTFuo10atfrKk4IO4EwAhy3O3/qVwLolE5Y4iLwN0b
			o4E9uRuhNSbfhc0mj9q+XladnOwamZGQ2V9BmC2HnjhiuTxeEGnZbXtFk1SgeROdYYV7bMpfBCyK
			5m1lei+x77ZPMbkFbJVebk4a6IX0sFBPtBAKK21pWpQzgTBvkXb1/cOcCo7McyRv37KUUq5J1Mnc
			oyiI7CF1RCz2SaaeNDELiGYGDG5sQsHnzI14577y5OSx+7aHXYm7PZ/eYxM7qoS+99OengjvvfRj
			71NnPVt3xU6AHkzqYlgKMfV1uR/TXJAlfw7AM2RsP+J8lCvRM/azQFW65bcs2lzunR0u1ya3OVjs
			QWopT8jFuE7W5xV0/PoPpoIsCC736Z7QupeSbynS0jqcIPpPe1LZXLNghTLsJmULkwTAvdwOjJ14
			mljVnKLJ5Xsd5wyb/+p/XCdpQVs29u0UQgYn9tKs/AN+zaFquGxSjYHWWlDXkTLIiQVDd5FaHH9F
			+ov0dVcT9XZlKE8J0MEli8ZlxS/KOWaT5WRmodL8Y0Nk1Jdn5E0Gf9ogmzEIoeq3EPT0IN/0y4c=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:35.091', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='928bcebd6ffc51a20055cbd182f269853f5de4aa'
			WHERE id_processo_documento_bin=3106783;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0000001-19.2017.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='02f56f148f1b6be19d9e7748f46e47a0', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:37.245', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='L17aK4RcBa4C+UTRZwbud9wdce9AcCcEuKLuEu1f+TPqnFzwpnei1C1nEEqUCoQvhH8q3hIbN9v2
			mVdQTbN8ZqoHZz6eki4RJMT1cO1S1YroW/1q/ydCLqDs0nrasrWVzTflD7PBZAONkiSiQsaNTChU
			YPxoRos4cS5Nm1OCeN/VBvlfW4t9lJlQOuhDGgh7VZtxcTXvNSJjVuEB60yqqeJUB8GH/6VICMiQ
			6GJdZDIqWL6Q3OD3QyBtxGXh8LB5a19GCiDHKODXDOYVrEBLJU9CgwnwbHdfiAXyDcApVwF2KdZ8
			D1L0GKKfGk32bczH97wG3InghiExpV2bR1+mI4yNqB7dyo6kMSSiAWxy3LIDSB7fVlGNXUvUU9Gk
			aHfAg3r7Wgrcd5hyTnic1WWBmoV1+Gae/7WnNQQtF99gMKKlr/JmWBUNV0v2AQNtdmtZm0IUEMKv
			pE1I8bD00KSL3UzTaAzjFHuLvQII9geZcyVWVMLkYJ/qIrVlKnWcnL5XOx9TW2A/iAXHLMKSLfrD
			BMYN+Lr0EZXTHyLeC2gOpvr99f+mNLRk3c1tHY3ITEYNSwIG4WfliU2Ep52VZNeDWDrZTXtsCkM3
			un83HNU7279h582p5Qfoxj76yKqtMisjffOXDlqwjUYMGlD57pKPZN0E50TAUe/wii3cjNH7FuU=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:37.264', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='bf6f4c58bdb23629c60e11fc70876e3f25e0ff12'
			WHERE id_processo_documento_bin=3106833;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0004665-30.2016.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='224a690abf2d8b649d016f44f100306e', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:37.797', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='Z6ms6Rz83wA+MaO5r/FSwU4w7MnONBnqjEijdfV+d/QPeX6lZjeC3JArR3HA8zmXvDRXqwEBsYeP
			pBQymz42K1/r1a93aFjRgFvF1wo4xG3QQf7RM8BzX56Bi4uHUTU+l3x/je7G9dkU8o9O4I8E+ZGn
			C4JxCzGouuSwxH5VfnCejJP57Y3pQHsmkMTendqxpF2rE1eoDa0wu5GjtzJ1b7N4kLxUoDw9yT0k
			fGFBDY5z3Gdy3VBOFoVWFzwcbNqEOlsYRupm9vUV5YZg91UsRfL4PgCy/1FRo9MyGLlf6eYquN3u
			xWsYzd/q/LclLa20R5uOzvXHiuidjMCFmwgtc/qg21qyDgrscO5hKS0EXl6fSBZvdcS6d9ywTXjQ
			hdOzL/ajyNmD4gvUadfakosAcXlnhoLvnOTzj+Hi0fgKLCdVE5S4ZM3BnKjcHcVo5o5zMX4YAnMy
			wSsPEuqKPwGo87YRU2klegjQ/hvOUcMXPknacxghArj70J9zpZ0cAYNhEcCnyxkFT2VG/bWE5cG+
			LELVx/7P9sPK3+6QGxyqrRUbvWbifUkxW4ynY7UnGneBnqA+aMn5locYIbDa4ushhU8jTULYNpSK
			AMd8Hqy2ly7NwTeO/w96GNMYe6JIRyszSS8uLlbSXnyAdk3m+FnLumjT1YO9ZUC3cqA9e+ulZuM=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:37.812', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='0b91e97cb34c857178ff5a2050df60c10674c53a'
			WHERE id_processo_documento_bin=3106883;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0004640-51.2015.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='13a9865785f1b17b736d37ff21055477', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:38.297', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='jNEjfcu5RfBb6cw05k2ErtdpFpo8JuDSJfi6oC6gsyg5y5WDF7RjGNCwm/kgKal7RDQzXk1PpGeE
			w5ab0OGCVjHXSix/DZaogp5+pjMhGo/ImEMDeM58pHxf92GlPCclWggAvOPuXM5SxBdvx5jtAj/x
			thmVzk3tEldxtW16BPU8LpKKabz4NOOe+P+wPGVK24LtJwO21fM6B8LrBnyr2msfRAZYqJnEKgtd
			r5xoL/kbzPnGOFpDFvih7/niOQ63MUzbBqFkuU0/7j15CizSrRq1n+LqV62RNUj+JWNmCrkwNdFr
			GY2IzyOFRsoYUaugvn3Okguq1D4dF8H+hRYpmldiCgrsYNQfIMvKUnEbL2nuNrApqbPMHzyweyQq
			HaDUUkxm9pAmH+pC64uHLU5TMH2Bir6Nc4KGjL5xHw8MMOKkXIfDA9sq2lotTsv/mgFVHM9cRiqf
			F91ouTDgd6IVtOS7yu4zRVMfgV6NykXGfmbY9VgWADfUKjhzwbqkDZM/3v22ZW74sWdH0YtFgEiI
			HQvRZRMTD+IM3W2YyuGu3Oau5an4LMDx5jGR6AEKmZWCrqUFFRe9xJCnofj5a2tosNWv1dgjGy3G
			FeeyiX6qtOzmfSfEMnIUs5g+ivR5vRUGdRlIFKerMF9wkql+93oP7DVQEZ8G0OTlfXqKF23szww=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:38.328', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='58e6fc6554b4d094d5897a8ca193785e225f4a64'
			WHERE id_processo_documento_bin=3106933;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0003475-32.2016.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='d048e5091ed883692c42ffd5289ba930', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:38.927', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='Rffxf7EUmlSYrG++OQqnKvSI4pyY6fdkLtl/CSWZglztQBb+b+wshV35GNHZ7NMdrj/pNrEYHXvN
			A01gBOcgiYzDiCHtToK3GipDUHOZ8HhpLYdYVGLzEAlO89NSEkBnRb1UzTQtb32fKeehrdaCaREH
			3q/tgTr6V4j1TkBfFmQhLHUAfb47iA8mhSLSx6gu7yGFTqMcTMk7xloZFeT0dNfLhp21ek9LO9/O
			nLzP2Jr2B5tNilZG4AS5ATpDUDxQEQSsPPXG3GrkSoHc6QELBld5TvDuuRVxQ2vLmTLBo0ouzQCJ
			54c6gHLx56Yeq48BnxftKb7B8P5CtJKSmYH9uQTGs3gwaW7P6zS+Lduq3zBUUITlg5eF+3Boy5b2
			nwclq3uTw6HJy3H1ie0i8I28X4s2p34uoozWCOHiQtyHInQ7Qt6h6IQtQypxnV751p6MUwa17I3c
			QuIo372iPxNkJ03PemgUlu1SZQfsRMu4Dpzc9WpQemGezLPYWyZfZmFzsVcMZmzbvSbP5XpHnGlZ
			M4pv0hTqPUGyvzgd3LauoU285ik0j4PLo7ESFwOW9zDt4ElGuHcuMihtLMrE3VrSxvUUHikfoPn1
			bAfQXGJPTG7HC6dxPJ4NsVR0HDa0jAMGVGtolrapBRJDdv//k5Q7jZTMDFeQlLWl5o93jB28ySo=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:38.943', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='df34d4d1b269ee9dd21e48c52598f7423ec523f1'
			WHERE id_processo_documento_bin=3106983;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0009412-86.2017.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='a1413ebd542299808937e03aa6b9fb70', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:40.488', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='TpqpKCz1qL2mg+iNUoTpjMG5hZxa7xT/bgW3aMPTUXthK95smwCOO8IRBTJm8wGUg9crfqHgB7Zj
			uCWoGbE6kaUMWX0N02vvBlPhpgrNVI5LPeZi9RvJ6yYWsf6aRXIabyC9xwzcFNT/8yqG0gYJ1jPO
			4XzbWHHKTU/toXxLBlW5BFaUVgzaZ25oaeDQa2Xm3gO++YW+M6yiNeS+N7MOhZ9szxtd/g6030dI
			JLL+kcA6CPh6p322sfpbF5WJR5ZK590Zw5qMWO9aZhGIdVfO8icnhgldn50MGSTcbB1qGudix125
			z1ACpKba1XtyhD+92OxkgIM48PfYVNd/bOSdgLEEFgSg7l2khTgYMNto3hMehmzuYqFCMRsaJTPI
			Q8ykGJfvu0lIUgh8g9VW6UHTuOh19bBxX2ly/T7MAkcSUH0TrvOYuPaxlqu8C4VDcHtl7y7Q5JKQ
			0J90Q8Q642e2w9JWygTxdyjw2dyWmp5ORlyO2VoU4zbQyvW1QDOYmvNOJBQQTvksIdgKEpi2TaGF
			hhbjG3kYAJIbW9XkL8gVzbUY0BfmN5XPC5Dxl/Tjuqdy+o4B0kiH6Mfwoxs6kJ2cPdK6+tZdc5eF
			+AckS42ertJS8P9mXNTqriPxwXz+lqlHGhFLmWGrErJoVdh3i+jtOJ+4SJw16LV6XYTChm8DoEY=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:40.504', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='0c4d633b50cc9c97da56d879ad808875933b47f0'
			WHERE id_processo_documento_bin=3107033;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0003598-59.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='1e1e64ea325d2cd39b3b25a645371944', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:42.164', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='K8KU50lv91rOAZGf3Odjgt+5bhTp8XT5wiQTxj2do/7f12E9CZmGTaN8y4gHnVCq5XvZSW/E6a0K
			S/43mXFlqkwN+Fp0hdax92qidyrL6QlVX/x8PrJk4noGPdVFVDdH9N609xF0M5qYf5aLkHJG1kuV
			q1k0UFCN5u7pUclS0hrW09RltHNRe9Do0eRtlwt9tR5qPQv3FHdiOY+qshh3qoJT/zxe1LfsnJOW
			mDPuFYXpaSyHa2f1786OCp2QEhlgYSXdc123V/n2T8DB7qYIqzALVYPUkFyLtBwGLFK5bkEHpd0r
			TPzgWzlMRhhKg8fUpmGfeSVLu10gSwlE9JiejjXbfAaKyviVcY6Xw4lJ4BBeA3mybAm1PT1wVcl9
			lGBFeivTAYDv0dSNkRBB+CsEwls86nOXLEgQNHfKXziY7b7WZJAeDSBIPRdYmjivmD4b/B86ElQ/
			IBW37gc0Dq8IUv2ilWPA4Owejvjbf9XE+BHmB8MFgiyc8lOin7RjIBCAtmgguJ6vqBkTMGG2GCP8
			h5AmGuIHfasUS3Ab8Jqmd7YKsRWFfvnGJ2aVQkBJG+0L2hfe1FpUgU56nlo2LgSE8pKcCFKVgd+D
			85G9CkAA5bYNPfsKIotGVVt5vEzHlkLyG1UoRxoj4NOHdzTzYHpVKCW7vEES0l5zv0asRUuxypw=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:42.211', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='53b0f65ea50d3e1b20ff746c4fcc45a052668a06'
			WHERE id_processo_documento_bin=3107083;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002613-90.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='32b98cfdbc10eaa971a19d70cceb3a3e', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:43.792', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='NwY2B9ZBDAT4LjGJa4jEaD/sokjWKTVE22zz2haWVPFvgvUztSEOOuk046jri5MVLWQkakG8x6+z
			pBYBJyzo050ijT9CE4gQ/5Dnw8D7Vh27npVLnTwP+Kv6gkdoBDTgnzXRJzZT1MtQx5oAPv7fndvY
			z64pr0KpKKzlSAsavPTiz7xB2GqWz/Zig5+rWPDXt+UhQ7O/spKYeLNouvQE6/9U2fDjvsJwQsd6
			1LdL5pVm6CZd1cQMqeFRxq5ilKX+iwgT0BktCwSDX06Og7IitfqnVhzQjjMoZdE9HBHD7YrfCHwG
			LGfDf0wph6qYy87S82leEK1xw7/fqXeJOpsxZxcF7NkVqFAsKPksuKJ1Zx6yfGZfYcXjARM3YLW0
			OmJ4dO1GRKscICzM5jwrKTRGR74KxZqDbVxlpNnOyCsJ9hmA6O5kf38Ox5L3Z0xH3fFUB4zScEWt
			x6W5b4Qs4W9U11pd3gpb9LlpigZMyyl+ZITF8jPe1rsIXGZRp3u3e0kUTa8RyvymnUUGC0ky4Nh2
			GfdzSqKRn5PQiHpv/4vUwgWr6W7HIk2szJf3hdnfPBp+KZF1eUc504CEYL3AvW/hbp5LYFZ8R0FD
			ZFX+WFeU/HcJB6IsI92i/rqnlHnORHOBmvjYjhBzKx356l6Ja4nvhAszXnwl3TGhOEKLYmOHpAM=', ds_cert_chain='MIIGFDCCBhAwggP4AgEBMA0GCSqGSIb3DQEBBAUAMIHnMSUwIwYDVQQKExxDb25zZWxobyBOYWNpb25hbCBkZSBKdXN0aWNhMTEwLwYDVQQLEyhEZXBhcnRhbWVudG8gZGUgVGVjbm9sb2dpYSBkYSBJbmZvcm1hY2FvMR0wGwYJKoZIhvcNAQkBFg5kdGlAY25qLmp1cy5icjERMA8GA1UEBxMIQnJhc2lsaWExGTAXBgNVBAgTEERpc3RyaXRvIEZlZGVyYWwxCzAJBgNVBAYTAkJSMTEwLwYDVQQDEyhDb25zZWxobyBOYWNpb25hbCBkZSBKdXN0aWNhIEludGVybmFsIENBMB4XDTEyMDgwNzIyNTIzNloXDTEzMDgwNzIyNTIzNlowgbMxCzAJBgNVBAYTAkJSMRkwFwYDVQQIExBEaXN0cml0byBGZWRlcmFsMSUwIwYDVQQKExxDb25zZWxobyBOYWNpb25hbCBkZSBKdXN0aWNhMTEwLwYDVQQLEyhEZXBhcnRhbWVudG8gZGUgVGVjbm9sb2dpYSBkYSBJbmZvcm1hY2FvMS8wLQYDVQQDEyZQcm9jZXNzbyBKdWRpY2lhbCBFbGV0cm9uaWNvIFBKZSAxLjQuMzCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKvP/EWgWsbVqLwSRYUwlftebsHunimNfozkTYQ0KF5HnT0talve+uXYls213nuYgA14PBV19EZzwWL0Xp4llApNUW5K3kL264VswNymwjFe0DFxTWXtVK30qgN8WkKb044NHoWXZB9AU54QHChmo1z4qk2PN6VjOBXfsAjB2s3mFKlSVMymye48h4ox5ZJdlBmBOC1/3C4zf2LO+gL24RAF3WGEKtnoUXPfvV3IpG1ibO7t+guwmbDROzh3Zt2XL4Rbg+9q+f3pDMZJhvcviMQocG/ZpqZ5dcKWJGcG2TGawDY1BnlCzp6USmmjIigMJXDdf1Zq1vpTCevtMuWExUNHaBGdd6WrRna53GVPrenExX46EuZ7jRwAL24BMCLOYYZFGd9LMF4N7KPmTpnWNrXffdVFVGIHx/xcBspCFn+zAWPGvRXeM2saNnrzPnu3CZzdWEiUK1i+VQ+ypmGiqeLRpS9WeVuRld7SlmriDHigehYOQiDK4YSExoqDELYoalbikRBJbBTSr2CyVVU0AjhmOMCrgee2vjcKiYPX8efVqLxmiqbIXotMR/lzHImNpspwQmugqhIOgeY3UkZ3pX4Ekh4fKUvwTaUfBETf9AsV/aq8HcapMzKAyN/izS7N3G2zGeoGzVMCChiO3UnZR3y/MGD+n+rmCnnMnwGGa0lZAgMBAAEwDQYJKoZIhvcNAQEEBQADggIBAK5DLLIzwTBJteTTcOog8xmYW9aEjRTWuncDigtdrYqR17vl6LS9Anycm4YKYsiKzPYWz7YlXkiKJdz/3T0eXXZxYZi3PbsAPB8gW2EH4zezBhOvueX9hF8CcE6LDt7kkVrLoBF3uyKbhzqof/K2LlmeY4Ofdo0FgwhIsOcTT9L/gSfvI7mt3d1zoT+Mu3LwF/yLBdFDGlSb+gDPf2RWWegPmZee0UCSiz1I/nrNNlMm+SXJl7PSlT6X9mf7IdIP4nzQXFWA/nN9aiyc4sl0ES7jOtwptnv7r9WXVDOK7w37mf1i4r84b0rAjRNzojqMLYR0NlZNUywhAYQp2zXjWjAfgC8QLll+fHofytphnfmGxkYknI9yctMp//30Psz900MkAJudulGzlT0MCVhLvUhrlgxEhnpn6e99Zk12qkkRj4OwBjDfLztowXyuoVHxNzCU/2z+uv/TBkqXzqiDfXog6srcwcyZJ6CRtjkqGjFW1b8w7vMnT1UyMdXEfIXLAvq+TJtAKG+73ez7/0aLQY2C+kgs7hg5Cjvwl2O3E77nmdRlEKPQcUZIwjLXk20p7WEtj8lvitcJ3Vib0z7noqMSKChL1pTCEaQ+qaScLmcnADH3uaujuM4VaWqkpj32QrNd9CaHjFvxbf28imkYxikstEbSGLjhtppxRf2mohhJ', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:43.808', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='cae3e6428056991f5309be6b3992d4c0a613df8b'
			WHERE id_processo_documento_bin=3107133;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0000768-91.2016.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='321f8cedfdf030b8b275adb354444ac7', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:44.385', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='mDfE7pXsO+c0EsVwOdDOZ+1dSmYPi7hW7xsgGqbhGSrl48TRy50PyNMwj31q+cprDk8LpJgTEFL0
			4gIQbAb0IE2xXwRgwfQULFsDftvhVxG/PxHOLyaWQu8z4IXtCWLd/NHOEl13/SlQ4vqBRTx8MObG
			8lovwhRrC45qxNrFX51zQmnzQUdXTQvQcFLwLvrM8Rv3X6NWrKav6HTu8e7KrFRC9TtVQU3z0CS5
			wYONdQ1WsZbslA1S/AppK3rW8LvPJ9HZvWTWy5YsPOlBMpnYf4tE2N9lxsrDxgWOft1oKfZGGyBR
			m8sXXF3AZF7eLptHQp3B+GxJPAN2jfLq8wZVC1sKbezJPbgULsfUIvvkMJ+O0VWky6GFdwfW5tjd
			ULllIsg5sYG2pRseCbriVNTDYpQoWOwkY8w6gTAZPRI2LR1BtW2ttWfaa1CdBa2VC5eq5WoViWHR
			1HBeqK5ntTX5Lr6yl/mkmXO+2kYaFSM6lSkSggPhjp9+QM8xfp2rZeVCgo8boNrtlyqAxFUFwI4P
			DBMpeE5s5AT7EdeF9AaDMspDWhWHy2PnFJ4x4+MOH7wYzpY4JYfG2fKC11V2TJPm+mQvr1End0Ro
			oP8N23b73yMTpmmAXb4fCpSjSlKI299mun/Awis1+xbcgkXZQ5qNdXzKpRKCBY+kRXEn1A1i7QM=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:44.572', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='921d1f8920064277cf8aec01162daa02c3adbf4e'
			WHERE id_processo_documento_bin=3107183;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0004133-22.2017.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='c93264876241b9857e6d45b9b56b4a00', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:45.066', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='nMFWND6RIm09ydZ7T/mSXBsvpFTvyZwGFTIOs414D/Voz3iSny1+VfeyW1O+JRxwZlhruRaR5opU
			S5BBaVyyDYMjIyR/W2dGvRb6+aleNVOn4XQrzc/h8/WadN4OGn6Sf8JICCZ3cmowntV8vxqGGqbP
			xINyXSbFsuTj2c6vewGHAIpcM2NzUy59pViv/G02tglRzBu3XHWFKLI7XCzfRiJZ6s+2LDri1QD0
			q/eiVSEl8zV0P21FQaVGYs5K9hKkbaviGwMULvd8CKxQ2n22mwCDcYHtsjJh6/WU/Ja0fPWZAtO5
			FPUN68ay9xvPQpZ3n7maNTVdyRyrovPoRtdyuk++CA+MqFLkY5u2pN6ZLvG9uqLhWyg4p98oRscS
			QIDXdHw7bowAWVhHjCCplU5PtD7h/0nlnrp0+P+Uc0j5aDmMtuFwrNh31Awkv+sS0+UjicefDKSA
			95gGN+6g5Jm06abispZ0PNEGmACzJ5IYEeNgB6dJenHbIkwjujGI4U+poMq4zJhz2RXSaOmT+mdR
			k18nxH9TS5gBPQYTVPdDSZ+X1PuzLANlOwRzqSBJb387FRTLTGahGpb4c9ZxDGW5iXkf6eIWgnaE
			qPre9gvjcwgF9wV63o5ZZMuUOA0TqHaH7f+tZxsUqVIdt+arMz+GZHlqubFTpiIQPC8dEuRs81o=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:45.406', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='84795a5a1ee0e82c70bbf2f02f38337f43d36a45'
			WHERE id_processo_documento_bin=3107233;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0001628-24.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='449aa4b397306cae6adb3662bc87b066', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:46.994', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='ZsJAPmVDYWF0tzYdnOUYHlsV9z9jpQP64EnlPqPsb82lYlPUhXVRjhZdzGRIc5yCqznZGLnMVMe5
			e5g7bqiRcMRZn5CK+0SKmVPaPCZshEC5xJe9ejg4Pt+DHGX799SrhVbp1Rgl2Kx7pFrx0o5RbYnx
			X15s6US53ZQPFHbVv32SQ1k4sC1vjtHKJoy3J/sxdJWALyekft4jNbMp+a1d+M6EMAf+4WwWikte
			zFcuDOo0p90Yy5ST9cmgXwC+Uu7UIig5wBG6vruEbp1jPZOnjjmktsQ88y4c/fVgqiWFUN/18Gij
			IrFp2wOSeGvSmzgzEDJzCdIChQSgX6Zh+Ngkwuym0N2ViGCkndAe06OokqZRapdCu4UVwy1cUMUG
			KriVlqi9Px3C92DjGaxtn67JyEZlk7TLJ9gZ+XbIoAr/BGTDJQOfKHHDRM0LK7OgzGlv5p/knIVr
			/kDRL5gCtb4Q1rYxE+vN6/wh40rNg1EHvkaE7n1rfAV7763016VaZiVCwtlUq1bFKFPwIeHjRGpU
			58oHAzU8a4hkmb2A+JXyteqccj7oL+V4aQKq+agfCpHc4/Sz4HOCQNKsfzwhyoLJ/gozH7HXi4L2
			khW7a8uqJhydSrKPR2Z+rubAeCSQShlU0yTOWEZeTHGUwmFzwlh1Z97ttNXrWDn+XlWuOpyVlcw=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:47.009', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='97e66bb64f1a6f2b481dd33029b81f9a23cc925a'
			WHERE id_processo_documento_bin=3107283;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0010129-98.2017.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário virtual, no dia 11-10-2018, &agrave;s 00:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='66bf9a9175a55ec5481d28948e6007b3', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:20:47.583', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='WFH52EZMWSgVll445D0RzRw4OP6F8pyVLb4OM2E7Vu6558jAWl357MO3X6tlz/OLwebrfCQ5TWIs
			FPQx604qo7DLboC7bUbNmtX+4bRstOXAH5dc4/fVJODBq8z7h/xjh8YSww5at6EHEFPHcVJz6KlB
			H/f1brn4vEd8EZ7yidBToqu01Kxqkp0/tSHuN2v+2z8EqMa2BMHFBYVlP/EuTAU9MaH1mBYQfXl9
			QmTVbsR3iD29/a0JSsmxMZ1v5S6Qto/OuROAPZ/ZS1sz8khB4YDe/OBu6ErEH56je5fnAVUIISqg
			+M7X4hn+9bnzrlODHfj7lLdSIGHAx5Uth2kgMyxjEyzZJdgmUEJg4IZA9DJS0qLAXMv8vjNFLm3X
			NJCp1YM7qIp1xoI8/NLHFLrILbgCKjxP0w5qXcyGRORPSfWaJ4sF4Erf6Av7f14jRC/AGnOzjSEE
			XPoqUAFG2i+HZox3pRc4mpx1EccJ1r0P+7ysB5r2UhXqiWr/Y+8pEKEFdqgXvLmn6ZKict/H2XsK
			Nt3ocOBzLavRCTvAXKLjJeiD2N2MQRHaKpwh6/FpNGR1dVxdXL/x1m1SjRxRHl1SNJ+TwLSscdky
			gn16ptYs7oPbxCH+evfj2jZEHmTPCf9wDX552Z/40nqJrSi0hbk9yCugzAEITGnBfhN3WW0YvAY=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:20:47.599', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='783605d429db2cbc0e3ecb4199edc5d3b0ef26be'
			WHERE id_processo_documento_bin=3107333;
			*/

			-- RECUPERAR PROCESSOS NA SESSAO E EVENTOS
			SELECT *
			FROM TB_SESSAO_PAUTA_PROC_TRF A
			INNER JOIN TB_PROCESSO B
			ON B.ID_PROCESSO = A.ID_PROCESSO_TRF
			INNER JOIN CORE.TB_PROCESSO_EVENTO C
			ON C.ID_PROCESSO = B.ID_PROCESSO
			WHERE ID_SESSAO IN(503)
			AND C.ID_PROCESSO_EVENTO IN(3255887,3255787,3255587,3255987,3255937,3255737,3255537,3255837,3255687,3255487,3255437,3255637);

			-- DADOS DE RECUPERACAO
			SELECT *
			FROM CORE.TB_PROCESSO_EVENTO
			WHERE ID_PROCESSO_EVENTO IN( 3256637, 3256687, 3256737, 3256787, 3256837, 3256887, 3256937, 3256987, 3257037, 3257087, 3257137, 3257187, 3257237, 3257287, 3257337, 3257387, 3257437, 3257487, 3257537, 3257587, 3257637, 3257687, 3257737, 3257787, 3257837, 3257887, 3257937, 3257987, 3258037, 3258087, 3258137, 3258187, 3258237, 3258287, 3258337, 3258387 );
			/*
			*/

			-- ALTERA O HORARIO DA SESSAO DE JULGAMENTO NOS MOVIMENTOS (503 - 37ª Sessão Virtual)
			BEGIN TRANSACTION ;
			   -- UPDATE CORE.TB_PROCESSO_EVENTO
			    SET DS_TEXTO_FINAL_EXTERNO = 'Incluído em pauta para 11/10/2018 14:00:00 Plenário virtual.',
			        DS_TEXTO_FINAL_INTERNO = 'Incluído em pauta para 11/10/2018 14:00:00 Plenário virtual.'
			    WHERE ID_PROCESSO_EVENTO IN(3256637,3256687,3256737,3256787,3256837,3256887,3256937,3256987,3257037,3257087,3257137,3257187,
			                                3257237,3257287,3257337,3257387,3257437,3257487,3257537,3257587,3257637,3257687,3257737,3257787,
			                                3257837,3257887,3257937,3257987,3258037,3258087,3258137,3258187,3258237,3258287,3258337,3258387);
			COMMIT TRANSACTION ;
			ROLLBACK TRANSACTION ;

			-- ALTERA O HORARIO DA SESSAO DE JULGAMENTO NOS DOCUMENTOS (503 - 37ª Sessão Virtual)
			BEGIN TRANSACTION ;
			    --UPDATE CORE.TB_PROCESSO_DOCUMENTO_BIN
			    SET DS_MODELO_DOCUMENTO = REPLACE(DS_MODELO_DOCUMENTO, '11-10-2018, &agrave;s 00:00.', '11-10-2018, &agrave;s 14:00.')
			    WHERE ID_PROCESSO_DOCUMENTO_BIN IN(3105933,3105983,3106033,3106183,3106233,3106333,3106383,3106433,3106483,3106533,3106583,3106633,3106683,3106733,3106783,3106833,3106883,3106933,3106983,3107033,3107083,3107133,3107183,3107233,3107283,3107333)
			    AND (TO_CHAR(DT_INCLUSAO::TIMESTAMP, 'YYYY-MM-DD') = '2018-10-03');
			COMMIT TRANSACTION ;
			ROLLBACK TRANSACTION ;


			# SESSAO VIRTUAL  = 503
			# SESSAO PLENARIA = 498

			-- 
			SELECT
			    NSPNAME,
			    RELNAME,
			    ATTNAME
			   
			SELECT *    
			FROM
			    PG_NAMESPACE N,
			    PG_CLASS C,
			    PG_ATTRIBUTE A,
			    PG_TYPE T
			WHERE
			    N.OID = C.RELNAMESPACE
			    AND C.RELKIND ILIKE 'R'
			    AND A.ATTNUM > 0
			    AND NOT A.ATTISDROPPED
			    AND A.ATTRELID = C.OID
			    AND A.ATTTYPID = T.OID
			    AND C.RELNAME ILIKE '%TB_PROCESSO_DOCUMENTO_BIN%'
			ORDER BY
			    NSPNAME,
			    RELNAME,
			    ATTNAME;
			    
			SELECT * FROM TB_SESSAO WHERE ID_SESSAO IN(498,503);

			SELECT * 
			FROM TB_SESSAO A
			INNER JOIN CLIENT.TB_SALA_HORARIO B
			ON B.ID_SALA_HORARIO = A.ID_SALA_HORARIO
			WHERE ID_SESSAO IN(498,503);

			SELECT * FROM TB_USUARIO_LOGIN WHERE ID_USUARIO = 7870;

			-- LOCALIZAR TODOS OS PROCESSOS DE UMA SESSAO       
			SELECT * FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO IN(498);

			SELECT *
			FROM CORE.TB_PROCESSO_EVENTO
			WHERE DS_TEXTO_FINAL_EXTERNO ILIKE 'INCLUÍDO EM PAUTA PARA 09/10/2018 09:00:00 PLENÁRIO. ';

			SELECT * FROM CORE.TB_PROCESSO_EVENTO WHERE ID_PROCESSO IN (SELECT ID_PROCESSO_TRF FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO IN(498));

			SELECT *
			FROM CORE.TB_PROCESSO_DOCUMENTO A
			INNER JOIN CORE.TB_PROCESSO_DOCUMENTO_BIN B
			ON A.ID_PROCESSO_DOCUMENTO_BIN = B.ID_PROCESSO_DOCUMENTO_BIN
			WHERE ID_PROCESSO IN (SELECT ID_PROCESSO_TRF FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO IN(498));

			SELECT ID_EVENTO, DS_MOVIMENTO FROM TB_EVENTO WHERE DS_MOVIMENTO ILIKE '%PAUTA%'; -- 264

			SELECT *
			FROM TB_EVENTO A
			INNER JOIN CORE.TB_PROCESSO_EVENTO B
			ON B.ID_EVENTO = A.ID_EVENTO
			WHERE A.ID_EVENTO = 264 
			AND B.ID_PROCESSO IN(SELECT ID_PROCESSO_TRF FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO IN(498))
			AND (TO_CHAR(B.DT_ATUALIZACAO::DATE, 'YYYY-MM-DD') = '2018-10-03');

			-- 
			SELECT B.ID_PROCESSO_EVENTO, A.DS_MOVIMENTO, B.DS_TEXTO_FINAL_EXTERNO, B.DS_TEXTO_FINAL_INTERNO
			--SELECT *
			FROM TB_EVENTO A
			INNER JOIN CORE.TB_PROCESSO_EVENTO B
			ON B.ID_EVENTO = A.ID_EVENTO
			INNER JOIN CORE.TB_PROCESSO_DOCUMENTO C
			ON C.ID_PROCESSO_DOCUMENTO = B.ID_PROCESSO_EVENTO
			INNER JOIN CORE.TB_PROCESSO_DOCUMENTO_BIN D
			ON D.ID_PROCESSO_DOCUMENTO_BIN = C.ID_PROCESSO_DOCUMENTO_BIN
			WHERE A.ID_EVENTO = 264 
			AND B.ID_PROCESSO IN(SELECT ID_PROCESSO_TRF FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO IN(498))
			AND (TO_CHAR(B.DT_ATUALIZACAO::DATE, 'YYYY-MM-DD') = '2018-10-03');


			SELECT B.ID_PROCESSO_EVENTO, E.ID_PROCESSO, E.NR_PROCESSO, B.DS_TEXTO_FINAL_EXTERNO, B.DS_TEXTO_FINAL_INTERNO
			FROM TB_EVENTO A
			INNER JOIN CORE.TB_PROCESSO_EVENTO B
			ON B.ID_EVENTO = A.ID_EVENTO
			INNER JOIN CORE.TB_PROCESSO_DOCUMENTO C
			ON C.ID_PROCESSO_DOCUMENTO = B.ID_PROCESSO_EVENTO
			INNER JOIN CORE.TB_PROCESSO_DOCUMENTO_BIN D
			ON D.ID_PROCESSO_DOCUMENTO_BIN = C.ID_PROCESSO_DOCUMENTO_BIN
			INNER JOIN CORE.TB_PROCESSO E
			ON E.ID_PROCESSO = B.id_processo
			WHERE A.ID_EVENTO = 264 
			AND B.ID_PROCESSO IN(SELECT ID_PROCESSO_TRF FROM TB_SESSAO_PAUTA_PROC_TRF WHERE ID_SESSAO IN(498))
			AND (TO_CHAR(B.DT_ATUALIZACAO::DATE, 'YYYY-MM-DD') = '2018-10-03');

			-- RECUPERAR DOCUMENTOS DOS PROCESSOS DA SESSAO
			SELECT A.id_processo_documento
			FROM CORE.TB_PROCESSO_DOCUMENTO A
			--INNER JOIN CORE.TB_PROCESSO_DOCUMENTO_BIN B
			--ON B.ID_PROCESSO_DOCUMENTO_BIN = A.ID_PROCESSO_DOCUMENTO_BIN 
			--INNER JOIN CORE.TB_PROCESSO_EVENTO C
			--ON C.ID_PROCESSO_DOCUMENTO = A.ID_PROCESSO_DOCUMENTO
			--WHERE ID_PROCESSO_EVENTO IN(3255887,3255787,3255587,3255987,3255937,3255737,3255537,3255837,3255687,3255487,3255437,3255637);
			WHERE id_processo IN(110598,83985,68825,92561,92299,101989,101676,90285,92980,9452,109942,110031);

			SELECT *
			FROM CORE.TB_PROCESSO_EVENTO
			WHERE ID_PROCESSO_EVENTO IN( 3255887, 3255787, 3255587, 3255987, 3255937, 3255737, 3255537, 3255837, 3255687, 3255487, 3255437, 3255637 );

			-- RECUPERAR DOCUMENTOS PARA ALTERACAO
			SELECT *
			FROM TB_PROCESSO_DOCUMENTO
			WHERE ID_PROCESSO IN(110598,83985,68825,92561,92299,101989,101676,90285,92980,9452,109942,110031)
			AND (TO_CHAR(DT_INCLUSAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-10-03 17:10');

			SELECT *
			FROM CORE.TB_PROCESSO_DOCUMENTO_BIN
			WHERE ID_PROCESSO_DOCUMENTO_BIN IN(3105733,3105383,3105333,3105633,3105483,3105433,3105683,3105583,3105533,3105783,3105833,3105283);

			SELECT *
			FROM CORE.TB_PROCESSO_DOCUMENTO_BIN
			WHERE ID_PROCESSO_DOCUMENTO_BIN IN(3105733);
			/*
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0008807-09.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='db8dcadee413531b3c9bd9bd3cd3b589', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:43.586', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='dD8Qu/Kl7FjtNlA/iauew+uUHwswDaN0ZJbu/928wwVmQe1dg1qD3ufn63jxlm3sHnAk3sqpCVjZ
			eM1jaETT+Ic7SigVgLcav3qWqLYQh8bH7Pp1z5RJK5Y5e8hJXwT5/nqTN5utnEUV5rgoffu5ASC5
			KeG3cdch6H91Bwra7Y3rKTScbv2WBx2xh3vmd7HxY3AKLwq8DBJQhr+Vtz+AGPu/eki5MqzS5P75
			MR+oknE1JiFVSbfzaklIxfYWmqWe2whd7y+ebOxkulUzwO69FDOsuOGzqkwRUjWaJQjI0azJGklv
			53axRZcc+1xOoVpVetUB/6edpEur+b20d41b1FEqYUpWrj7ToXB8sBiqa6Z7Ia3ALpa3/8XP04QM
			XG5vyC8cXZ6cMoHhMGQ5Xd7b8qiu7J9C5maOaxTBRRg3gWLku7T0EzNaNbV+ECfT9TFhqM1FY4f5
			W9i65k6lT1a8omFYKtxibEZAkxa01468I9/2qughVtYOb/TA8Skh9ox8nDR+OVASqCbfm6di5J8F
			8B0q2J4HYABIKGZayLL6doFJnm3Y9A5h5TyH30Qn3MfXj/Lk2U6xYk0u3kw9xCnfVwfJIGtZEF83
			TQNbDMHXNJB//mZmW6deFIgMsGvw0gLnZWMdGuBkKK5DS2zn+yiyP2qhdGh3210I9aVijJAZR3A=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:43.970', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='e4f7f6943117a09d5b08a3ceba145cd912ec675d'
			WHERE id_processo_documento_bin=3105283;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0000498-33.2017.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='4afef4f18bcad6062dc01999f8da8fc2', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:44.831', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='Jaigm/6ZEglqHrygAlql93as74WBkUajLiZdo3E6jyhj699iv3HNuFwuNt7ztAXfnjKsj83tvc6y
			RN/d+nRR0IegNv1XFXyP1kazhjSeNqAFU/nsIf9d4eXuI5OEzR/WG/cKojiZj7E8QWrXxjnhazcQ
			uY9ZqZ+q3Uv4noT3o+jis6dkpfO9+egcOgcVPv88R4QO22kxcSsUfWhytpAjr2s/kfeErwH/v1t3
			lf7SWLF+D7KHf4m/qhTQkR+bhjLor1nyYQ4QduOyXut89XB2uNk2BFSF8vSIErEUhObISY5yPfwJ
			GoAnCepFbl1G+tviDrkJ+DFjogmmjty6JImj/bPsjd1cs1WCbHu9j4PAJDaDE9JxUe6c0vsFULgM
			ToJlGuNiAhxItAdSxwtwEHkufVYI5PaaCGnAnU6Hubq1CQoFnvzNAT7v7CmHc/LJCxeCVmutRVmU
			O7ceG0jDTjo0AyPjeCAtjEOYlgIay/+7RyNHQBNqBFv+eSJiKIvHGuF8/TWpC2X4fpyZdYbfbweZ
			QkbO/h/81e4IOqlKC/D5zOi7L68HH22VjCIuTGYqBPM1a8EPGBVELos4GMW7Gn+uGSQI1CwdklJY
			a/JDbR74IEg91bhXBH/Zky/NpWPOJXT57lmTl5AmtJZXnkBQIjVxPP9d5/zHT6XYfd4D3NEq0KE=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:44.862', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='c58e3002c04480bc3cacf12f9d46eaa978baa7d5'
			WHERE id_processo_documento_bin=3105333;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0005142-87.2015.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='c3ac3e244f93ed709ee2316e5384db85', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:45.544', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='Z/bA+Fv/gEiJlSizgJHxFCO71xLaaV8wxfPU8Px/NrHA3oNUp4mDEkKnkdQgXSjhc7WP30BICOr/
			7xpoDfgJSzxSv9JHY1juBEboCpod6dJz7TJA9g1XEjXse632+om5aMuU/Lw4rG+kZGGrd/pxkytp
			n0B9AMalWv18rfmM2Q/arEuV612lLu4BPEia2w135V5DTr8iS/eAZltLWjApiYbFaHzhhPSLa8H1
			eKY14n4qVlyRAm/kIMta5j2chlnP1vWoiFzEyrB8GwBl6vl0NfFnHRh+RRWz3kM3OdOWIoHq/Dtq
			ZHmaF9y6AkEv3W2bK4DhKtwHkm/gV+ldT+jYWVbPwpb+lNtSDGLHVaMwXl+gqK2y0ZRXMhzlg37U
			20SUmSGUjNS01IXKw2L9mDHSyYb1sLJbS710ZVs0khqWmlCxnpMEbY4kCNiHsey3e4CIiW8H5wk+
			7j80Nqgp6e2C/1goPmeZtJWI5ab13SfidJHNtjPkW4nf68GZiob2e06maOOXB9ZZInGOLY/as9Ro
			WJR0tIh6JiQ2DbixXdEnyDIc0MQTgoHHHwmtuykCy93B8tXslm6RzOm8WesChFU0bnViXDrP0lMT
			F9HF6nXtWw+q8kNSqN67NtMc88yr1Jbtj+oFPHz/Jjz0rei1I0IVbYJu6yKAQWR7qqHEz5P39q4=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:45.560', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='5aa41e5c01b302eb05d32d49bdc09f8fe40a09ad'
			WHERE id_processo_documento_bin=3105383;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0006315-78.2017.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='f15ff3865aeb65ee0941b2cc956ec06c', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:48.443', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='kg+OunnImDYj1ITmQPNiTvG1/ysKehg7Oy/Tz76Fubt2tQkRKLXt/waTS74IXoJFUsFqy61MxRmD
			sWj6ngI6BsUiPo1lsHnW+OPuMPSbkCV3UHqVdqw1vZZO4wx2yT6x28YJpVnQATsD/bkZV1yWByur
			CVoE176B1aNGrlqCe5M/wZ9svCT2ARUBR0d6G7oGdvcSgfuDKeLbzVMliMQr6QCPXBrhaa3kyJEY
			zvFDAKBA5eaiciUiWWoJUZR93xr/6fETxJvGG8K29Wiw3xEXljDQVGMX7Q1s0xA7s9J7eMAHDu4v
			jrzBPE9Chv2tBrQFb0hIHRuttsYNBa+tLXhK9SDeiNM3JvnmPqiC1PC04AISWifaOSum+Rz70VMo
			rsvY3bJp61GZ9eycNXMrEjHUFDLVGTvzSOjJ1x3QzzaqGzUGziwjCxyQ6LSymYX5ez2ei6DFa+Se
			7ft5nZFbWWBTNCctfcSA44/Wz6Ckus/PpDRQJjPGfwyGEeMWGqaDsnotiDO3ghddO2AE82tJakys
			ADx9Dp6ERE0K07z3tTH9g55Zz6YCio6TcqML0IaU8QLFeJLoPWopRHBv5czkV6IJnSXIgtnxm17y
			1AHkjMlvybWb3n1YL6M88Wnyo9iYG+2nizIEFqsXn80e9YaIr63NYIEH00QVWoqvQVTJ7KvFKnI=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:48.459', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='75ad285204e0e42f92865025ec57fb940823807e'
			WHERE id_processo_documento_bin=3105433;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0006134-77.2017.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='0e176deb94d9a6b752e3694b2cb47ecd', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:49.349', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='WiX4YjotVoQ/g1Kvl5XISuWGmI70QP1mIcouiybklbXJIXgj7znADCwjPDNvNuqATCoyEMgKlDxj
			Gsj1Dl8cA+w01QRd1QhtBUgVnlYK47ma+dN8Qq5DN3xEEmcdKtqyxZswd1h5JKOr9ykF+9Z0v0W3
			Z9KK0AZ8m7f6vmCqaN+YklSDrgwdXX+gZTheE3bgHCiTCCm5/+0dbpoAR060RagHljAWvOLH9HAG
			DPTCXJTF5UHuKjCffqNxocEev9JSfSpj6gua2H+vVnVKAkwibOqqGhI17EWpRjUjBzjtiK/HNz2m
			n486knIHPdH0AiDYbSmc2V+PhLtgR/cP1rkX5i9aWFoYNgGfQXZWGE0YAhTSR/+bDG6uVDPzr7FS
			FwndeNEVRoYcrZyJX2p9Sk3bEh1QLLCcy8/rHd04gxUGbiljZgBe+vMA8UEGgdm1HANCR1o36l43
			0DWlAHSpfB/RVIikyMdOgXKywqipxPRKkddKB8OqqeyZYrxt7t2+x83cizIR3y0u6os4ldX6l4+M
			9w2IzZY+isY2/zJRixFRsgVNJHbmgEQLEasZXeIpIZeNF3/6pA4MCebc/jZehAmINNUVLSo7GAm9
			spQu3X9vyNFY7jB68SEcV5CXdYzy/La3L7rzUZdDgp6q/CmWpB+8mjPllBHTKp8A7T8WaQxfkww=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:49.381', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='c8661f57ef59d0a8057b03a229cef8627ff3cb68'
			WHERE id_processo_documento_bin=3105483;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002464-94.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='3d24b1dcfa3ff77d03c6d733ddd8e24d', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:51.138', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='En3LaN0SFkec57LGjkm6dW5L2DjKbapFTOC/AEOYQbrgQbtTHZvrmwE5D4Oo7E+zaxJuWyAg3hmU
			j98hsllLUyC5IXU5x/ZdDl4vQs58NGSdrTulCLZhf6Qhac+liWr3HAU8K4TOIP93NKKXFKhUpaQQ
			UPQLahlXOYw3wnjuDJ9XkqWEsEN4QBsy7x47+MdOSooX+ctqmZiEiDZdqx0QOIrZG3j9rb9IV9/f
			sBXlY3xJBYFTLn4prwM7IT6KSrsRSftTEAWrm+2yg7y/IwhW8buSNOTenSwjc+yuEWWpowEOBk64
			URThLAjOXfxtfC3rz8qGaFzzsJZiTWQxCftq1gFqXk3UKwtZEUJ2qm0D9LV3tpO4yFY4VuSixuo3
			B9OL/SAgZLAOEtsVWBcHJnCT0DMoeey4ifQiERHipIliVwP6fzN7PdiWtZSKS7rE3f2Lf8vIW48E
			vTwHHTu8CJ7vwpyRgzQ1NgxSyn+j+NneneaUJP4K4MD58/HECVhtGm4jxQpGRmPUL5hULGkrkiX0
			kFgLoRfWOoc7mcsHSVYRmTIZ50FEJ6vlhljakRiuHqqyVXQY3dJOz8+JZWsQOv/b89Dh7kOgWirV
			rDuWz8byY04Wms8xpfFrc+W7Adgq8Qds+Xz6erlRspqVE44q6TLd8S2Xk3X6J7oS9hnoVjMc91I=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:51.153', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='c6ca3d21e6410b91f13535d6736901c8a05bb81a'
			WHERE id_processo_documento_bin=3105533;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002221-53.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='56d1bb53a66378f0c2c60a815227d1fa', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:51.609', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='YZ2EHV00kc95hJ0WaeMsypUsVcapfwbrupIrVhV0UcJKrlGgKAxfqIrv86O1qs563Qa1CynUVgdP
			EpEStfDFP/E6lC6wvOr2qv6ZXO0CuDpttfs3VIqa1gkKDjQo8YzKX3wKrHh8MtcMahkyg98ODn/L
			LTv0M50+WRjmY72ekKnX2HyJryfKmPnTLwE62kZUUhZjBiFt+NQeMFgUSKky9Ufvy/uhyeYuXh2Z
			4j9CXJz3detUS599axR3Gp2PI5U2bAUaJfi8ZK1d4v/tXC4+ejfLEdepePBzH+ZgVkDyhV6ARnkP
			MsxmsEhUMmc/HoFqNU4u2LNSPsloO2UYjCpUE/gK/lMYgT9bgPFr9EP7TSMSFtuqR98WdBR7v2ij
			cj+HcgTrDE/H9YyuEXS0pFRNAUP23d2CrbHSjvh4k2KT48yBabRgZt1KFomq9IYyomE76G3mPQEa
			G52x4vrrzAtXKowhNsNJUfZITIbKTG29X303t6EVl89KXFkdusRRJg6v0F8/T+4NsMk6bQFCE65q
			kPvWXwhLODmHI3LZaffTw65vOs4iVKXBX2iX0NElM+Pr0JhIQxbgUFKSgVXhzdVeDbGebq6mMWMZ
			tjrKZDgUy7KgS2ytaayEzjum7vN7wgofgpaz0/rUgtZXMp8VxLANMe39k7G9P9ZT5UgIKp29+OA=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:51.624', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='71f25e2fab287d3cd2b7e90207f546c4b0d67dc7'
			WHERE id_processo_documento_bin=3105583;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0004837-35.2017.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='7d0035a71319f7df93ec91b45d14a0bd', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:52.379', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='m8GUJRx27XjVJn/48IysHr/KcekkZdvstnsoWJIJGsCmLVZd1sA3DJda3wLgcDEMPQZ6LJV9SeP2
			wRl4ax5naK7acFGOxsCLQyhljDUaayuXw9myKpSQ5kQYpfKlQHoEfnSkRPRnr9X/1ZrTg4EItDH/
			r4kuq//+9wgqhJornThjeWoaZOE+1cP0DOZWe6S+B18RZJXua1U6E1WKSZn31koYvKKmvVTxb+md
			iykizvWFSZNgMPu1F7+g743uW2XTlOci4iCw7O1qn2T31H/BOU78OtSfZdGb2GFsxZjMJDuEGGtb
			YZKBPrsCFZPhYy+C+cpStakRvYx8WWGhMqPXrScAbgSRPDZhsD2ZWObt3nh9XfJ25srEauBpAyQj
			LdGEEgyWql2nrZsB+9qM/QUoSgKQ0SiNw2sa1TYaIpiUyEaZa/L2L5MFokxr5E7ZaWo/H2xuP3w/
			/r7rSMJooQ/bQ3rN7H64SFxdVTIvclb8yG7FL0pRa5gyvofQyO1dxOwlO9k+GCYw1J8KnXvNrPT2
			Vj+lBFLX+nj5xFqIBYfXg2YSz9fYkKo7bVJ5M+8l+S60qgrytINt9OeI2Y8DzvriUquE++uYOCJW
			Rh7KT77KmcAbGE4Hq8jRhPUKHmjnjHrpjAS1Vqdghn2x+Voh/LM2H/1ap5Ei/Z9R0Pcfjxk+iII=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:52.395', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='e70c3c3a67063f8eaa9e7b7f60d7574661620063'
			WHERE id_processo_documento_bin=3105633;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0006598-04.2017.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='b01470d22094d63b8ad0948064e3cd8c', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:53.928', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='PZRIeS9Mt65kf/s0scsgo4Jy05ta6BeybOxIkHF2Yxi/jaLRvsYh/kO7uwZl4Zhf5NvjmXfJ9liD
			ybt/oysHZxkaAi6pGdb7MH/phbkeMNPTO4ahNyHXvtIE74kRPwgrYM2DZDOOSoOdrC8MetYxl7/y
			5fjJBNizp10VJPBNsp+dyYsGnis1FWyJMzPfnbGnlHAPjaUR14mJpXYQMSPW6BSowZqqg0a5pIHA
			BCWiZb1Eh0ugEWkNsHePR0OCWIufpCpSvk0iP6VATewzRs4mvuVQxVklsd2XLCziTQOZRPWJyjl7
			RYuKZimvCTtbavyBhDi5J7b6ZXDDdiTj9HSQ1gshOTRdJ+e0bsP6mdFr8AhrSgeh0YHAkVsBRwpV
			vRPJEWsMvmTOH5Wi6z/woQ2fGSlcA1ZzCZVANamxmm89GanYIACUZFWJoMkIaUS1EkKsgOms/5BZ
			d+oxbAlhwseDzgN55fmHxZv8JmIaEzU+AWmMsnCOQGWQl38lBDYNB3nG9UYM5uQkpITA5kWZsafX
			3iQBKNGwddiyiOBTWRm2xTU/ALHucTPmXFNP6m3RFUv0xH41Xb13+a2pnwlQvAqMSsaLEAymjnB0
			cVt6905Fq2FtzHlA3BoZahDMab4Ttuw441dI2NIx9Mh+HW8Qf/oiXbY6gdYwF8oRuZvYckfUHhw=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:53.943', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='c64b7f3c2b454d699fda57d3c7995de75830c422'
			WHERE id_processo_documento_bin=3105683;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0002330-77.2012.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 14:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='1ca977093179148aed751508b18286a9', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:54.415', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='DlZKEWGVCqtL0f7vc/xRFsvQmVJLeLLR/tFZe3faWWm/ll8liMOl1GsAbSO2yL2M1YK052lcHJo0
			Bt2PROC4v6toVunsGo9kqx1bw/7xwhc59M6mzKT9xmD+N/bukQYzqCgw/33Npko7yAVGqM8N32A+
			ukOJGzob7zXJrgeWAuJf1MX6yAC9/jukFlg9KDeE11iLctLUnQun7u/bvj7PcNnbvwOnqqZyCxPS
			7JuRqoBaH9GjZS97nDkbMJnJuqIThPCv7JhEMhhDlzSGAxAsl83dFPexMPdXh7NhAcvWl8QG9dle
			PPhSL8uai6gq0+SqUsj5TGpo7vmdTbYQ1Rb/QUU3IwnlyHhxt7SM4vdcSy891y1aO9s7W+Sfen4T
			IWW7OwxQhDWVc9UASBbG91hMATCCYP9hA6k6JaZTgDpvhJ+soOWSwWM2h/lQo1e2E2NJfRZ1MmCN
			Ix3Hdu34UgZ5ztHMsg08VN8bUkrVzw/vV88cHkZhPU8Hw922EIu9k/Xw/L++jVX+8Xn5W/VmsXok
			eRZkvYSbpTB3qoTS+8auYjDPJP88aPLSXgDxxp2mZvMNVjfTK0O8kZz02beg2/rs3QL1Tqrsq8ur
			mGjIyflY7T5x/amISZlD9PXw/7bEW0iGykLwcXY++5R76fKI9Pgi7uihVvIfLdcBMxYaNuiU6TA=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:54.431', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='a116abf662db8b867412c80ca87e657b3f5f1269'
			WHERE id_processo_documento_bin=3105733;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0008374-05.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='1a9d8ee7d424103a7e9fd908b7de6d3e', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:54.901', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='lQTOQAcjhOkv1fAib1XdMTTdSE3dVErqMjTlbVdFajaSviT5FMjzAnHwPzDqHJI6hIaJbQsrEHtQ
			payi8iDriFYIjt5PD+8LsZQpsmDZvlfMP3KHNX8uScpT+YrM9xvPL7Ck4nIBbxhFxTuUZmfvxyir
			bkYW5nwMFhXoOc4BhFgvtNgWl1rQEDOQnRWhqzr5rB/kpNPKyc4OvffUMuNQ1PPP39IKYvZRIu/+
			mCgSKcN47II5FLiLe9T9+iNKjU8QmZ9xAdzWvYo63yysJFW773NGAtbwd29zvaFziuKsTUTvK4Ix
			vJwADpGGFcTtqkd31saxwxEtfoEPEF19NJxiz7uuEYvLaEmP5VJYN4Pl4AxvlbWCg+M9RkGuukz0
			wzlkEuRKfidfY3qRfo5Qt+npuFbwtgp30YnJZE62Hq8G8FFX6tLYXuF8gvky7nUTp+VTkOakdknL
			uUT7wHySmCI9W6V5X1jEff4BMB2kuvWzESPsY+znjJV5f73ek0cPYUya7U7W/je9hc39U91Cw7Ia
			rQz5EvWPVgre4OOn4jm1N+eqxuiCf8jGbXz7SBRCykVvNXSBFZHc/M6o+PhM87yx/FcH29/2ryda
			p60SM8c19M7n0coSrIbZ6Iz3lkKW70N+ueQrlk/fpVNR/PxgHQqnG0ofxVW9oPCU44H7nJdfQWs=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:54.917', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='030870a9e5464a3bf68a990e7dd0aca7f9d07b8a'
			WHERE id_processo_documento_bin=3105783;
			UPDATE core.tb_processo_documento_bin
			SET ds_extensao=NULL, ds_modelo_documento='<p>&nbsp;</p><p style="text-align: center;"><span style="font-size: small;"><span style="font-family: arial,helvetica,sans-serif;"><strong>Conselho Nacional de Justiça</strong></span></span></p><p>&nbsp;</p><p>&nbsp;</p><p>Processo n&ordm;&nbsp;<span id="variavelGrid">0008429-53.2018.2.00.0000</span></p><p>&nbsp;</p><p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Senhor(a)</p><p>&nbsp;</p><p style="text-align: justify;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; O Excelent&iacute;ssimo Conselheiro relator do processo acima indicado <span id="variavelGrid">intima Vossa Senhoria de que os aludidos autos foram pautados para aprecia&ccedil;&atilde;o na&nbsp;</span>sess&atilde;o de julgamento a realizar-se na sala Plenário, no dia 09-10-2018, &agrave;s 09:00.</p><p style="text-align: justify;">Bras&iacute;lia,&nbsp;<span id="variavelGrid">3 de outubro de 2018.</span></p><div><span><br /></span></div><p>&nbsp;</p>', ds_md5_documento='0ef7f0caeb16298dd37b119786182007', nm_arquivo=NULL, id_usuario=86978, dt_inclusao='2018-10-03 17:10:55.356', ob_processo_documento=NULL, nr_tamanho=NULL, ds_signature='b1ahMa3vUyWgj4pVL7hJ4VVSgCBkfv4rhrBHkWzseiRTJdwIzsIv3qv1RzIt7taAmKB1sUbf3cjM
			vZ9ua0LgKLkMtnzzlNyMk/TGzkDU2H2253knxRRn43N7mYhpVTm/zqVuQEbTekSnmkz84gpomiTs
			4zm/GT3XdpufjYC9sXDLbZpxTiDtNNZWDYNSgkOvhjLewcnHw/YsZ5M7MMBY9Oze2Lut6JYqZgNq
			kyCNnkiuexJ7TbvGm6fMdV0KhRo1JhiImlZJsFN5cwCJOLLSjTdJ481eSAo6sWPvYu5FxPZmxnJv
			CTcVA7x5JkbEgODnnCM9z6hDzJvdENRi+rm6eVSijA9g1USL+NbXSfE2AMMZWkRdJUGQBIfXtR/r
			r9rRk+3A656D5WiyoQnpMKJnZVq2DtPt8Z+OFzBg2U7MiGCJuDlHye36jc4R5AkJYDlXFKfrfeZH
			V7o1hIdLHqFaheVhoLzzOJZ9OGDI901GUsrXLY2xRYkcOo7lF6nRyWlUh/HE6XwKWvLO/63Z/3fC
			5sq9fxiwhg3WpWqircKqaRTskT8dQBxpUtF0b+TK9cqFRznLT0Q7GwIUuxf7P1wObJIXSJgv5Xb/
			KkqHdRXZRRoCJv6yZC8OYDH8jH0wMS19CIiXSbXY3ZiLVEvBPNjuw/7L0sSk+gde3shxc9NcG54=', ds_cert_chain='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', id_usuario_ultimo_assinar=NULL, ds_nome_usuario_ultimo_assinar='Usuário do sistema', ds_nome_usuario=NULL, dt_primeira_assinatura='2018-10-03 17:10:55.382', id_sessao_pg=NULL, in_valido=true, in_binario=false, id_pk_tb_pro_docum_bin_pg=NULL, nr_documento_storage='989756d53722d387141a8f2f33c9d3979ce66bbe'
			WHERE id_processo_documento_bin=3105833;
			 */

			SELECT REPLACE(DS_MODELO_DOCUMENTO, '09-10-2018, &agrave;s 09:00.', '09-10-2018, &agrave;s 14:00.')
			    FROM CORE.TB_PROCESSO_DOCUMENTO_BIN
			    WHERE ID_PROCESSO_DOCUMENTO_BIN IN(3105733);
			    
			BEGIN TRANSACTION ;
			    UPDATE CORE.TB_PROCESSO_DOCUMENTO_BIN
			    SET DS_MODELO_DOCUMENTO = REPLACE(DS_MODELO_DOCUMENTO, '09-10-2018, &agrave;s 09:00.', '09-10-2018, &agrave;s 14:00.')
			    WHERE ID_PROCESSO_DOCUMENTO_BIN IN(3105733,3105383,3105333,3105633,3105483,3105433,3105683,3105583,3105533,3105783,3105833,3105283)
			    AND (TO_CHAR(DT_INCLUSAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-10-03 17:10');
			COMMIT TRANSACTION ;
			ROLLBACK TRANSACTION ;

			-- RECUPERAR PROCESSOS NA SESSAO E EVENTOS
			SELECT *
			FROM TB_SESSAO_PAUTA_PROC_TRF A
			INNER JOIN TB_PROCESSO B
			ON B.ID_PROCESSO = A.ID_PROCESSO_TRF
			INNER JOIN CORE.TB_PROCESSO_EVENTO C
			ON C.ID_PROCESSO = B.ID_PROCESSO
			WHERE ID_SESSAO IN( 498 )
			AND C.ID_PROCESSO_EVENTO IN(3255887,3255787,3255587,3255987,3255937,3255737,3255537,3255837,3255687,3255487,3255437,3255637);

			-- DADOS DE RECUPERACAO
			SELECT * 
			FROM CORE.TB_PROCESSO_EVENTO 
			WHERE ID_PROCESSO_EVENTO IN(3255887,3255787,3255587,3255987,3255937,3255737,3255537,3255837,3255687,3255487,3255437,3255637);
			/*
			    UPDATE core.tb_processo_evento
			    SET id_processo=110598, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:05.633', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255437;
			    UPDATE core.tb_processo_evento
			    SET id_processo=83985, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:06.306', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255487;
			    UPDATE core.tb_processo_evento
			    SET id_processo=68825, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:06.997', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255537;
			    UPDATE core.tb_processo_evento
			    SET id_processo=92561, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:07.763', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255587;
			    UPDATE core.tb_processo_evento
			    SET id_processo=92299, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:08.944', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255637;
			    UPDATE core.tb_processo_evento
			    SET id_processo=101989, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:10.207', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255687;
			    UPDATE core.tb_processo_evento
			    SET id_processo=101676, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:10.844', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255737;
			    UPDATE core.tb_processo_evento
			    SET id_processo=90285, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:11.577', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255787;
			    UPDATE core.tb_processo_evento
			    SET id_processo=92980, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:12.724', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255837;
			    UPDATE core.tb_processo_evento
			    SET id_processo=9452, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:13.383', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255887;
			    UPDATE core.tb_processo_evento
			    SET id_processo=109942, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:14.059', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255937;
			    UPDATE core.tb_processo_evento
			    SET id_processo=110031, id_evento=264, id_usuario=86978, dt_atualizacao='2018-10-03 17:10:14.767', id_jbpm_task=NULL, id_processo_documento=NULL, id_process_instance=NULL, id_tarefa=NULL, ds_nome_usuario=NULL, ds_cpf_usuario=NULL, ds_cnpj_usuario=NULL, in_processado=false, in_verificado_processado=false, tp_processo_evento='E', ds_texto_final_externo='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', ds_texto_final_interno='Incluído em pauta para 09/10/2018 09:00:00 Plenário. ', id_processo_evento_excludente=NULL, in_visibilidade_externa=true, ds_texto_parametrizado='Incluído em pauta para #{data_hora} #{local}. ', ds_processo_evento=NULL, ds_observacao=NULL, in_ativo=true
			    WHERE id_processo_evento=3255987;
			*/

			-- ALTERA O HORARIO DA SESSAO DE JULGAMENTO NOS MOVIMENTOS (498 - 279ª Sessão Ordinária)
			BEGIN TRANSACTION ;
			   -- UPDATE CORE.TB_PROCESSO_EVENTO
			    SET DS_TEXTO_FINAL_EXTERNO = 'Incluído em pauta para 09/10/2018 14:00:00 Plenário.',
			        DS_TEXTO_FINAL_INTERNO = 'Incluído em pauta para 09/10/2018 14:00:00 Plenário.'
			    WHERE ID_PROCESSO_EVENTO IN(3255887,3255787,3255587,3255987,3255937,3255737,3255537,3255837,3255687,3255487,3255437,3255637);
			COMMIT TRANSACTION ;
			ROLLBACK TRANSACTION ;

			-- ALTERA O HORARIO DA SESSAO DE JULGAMENTO NOS DOCUMENTOS (498 - 279ª Sessão Ordinária)
			BEGIN TRANSACTION ;
			    UPDATE CORE.TB_PROCESSO_DOCUMENTO_BIN
			    SET DS_MODELO_DOCUMENTO = REPLACE(DS_MODELO_DOCUMENTO, '09-10-2018, &agrave;s 09:00.', '09-10-2018, &agrave;s 14:00.')
			    WHERE ID_PROCESSO_DOCUMENTO_BIN IN(3105733,3105383,3105333,3105633,3105483,3105433,3105683,3105583,3105533,3105783,3105833,3105283)
			    AND (TO_CHAR(DT_INCLUSAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-10-03 17:10');
			COMMIT TRANSACTION ;
			ROLLBACK TRANSACTION ;			

		### SCRIPT DE CORRECAO

		-- ALTERA O HORARIO DA SESSAO DE JULGAMENTO NOS MOVIMENTOS (503 - 37ª Sessão Virtual)
		BEGIN TRANSACTION ;
		   -- UPDATE CORE.TB_PROCESSO_EVENTO
		    SET DS_TEXTO_FINAL_EXTERNO = 'Incluído em pauta para 11/10/2018 14:00:00 Plenário virtual.',
		        DS_TEXTO_FINAL_INTERNO = 'Incluído em pauta para 11/10/2018 14:00:00 Plenário virtual.'
		    WHERE ID_PROCESSO_EVENTO IN(3256637,3256687,3256737,3256787,3256837,3256887,3256937,3256987,3257037,3257087,3257137,3257187,
		                                3257237,3257287,3257337,3257387,3257437,3257487,3257537,3257587,3257637,3257687,3257737,3257787,
		                                3257837,3257887,3257937,3257987,3258037,3258087,3258137,3258187,3258237,3258287,3258337,3258387);
		COMMIT TRANSACTION ;
		ROLLBACK TRANSACTION ;

		-- ALTERA O HORARIO DA SESSAO DE JULGAMENTO NOS DOCUMENTOS (503 - 37ª Sessão Virtual)
		BEGIN TRANSACTION ;
		    --UPDATE CORE.TB_PROCESSO_DOCUMENTO_BIN
		    SET DS_MODELO_DOCUMENTO = REPLACE(DS_MODELO_DOCUMENTO, '11-10-2018, &agrave;s 00:00.', '11-10-2018, &agrave;s 14:00.')
		    WHERE ID_PROCESSO_DOCUMENTO_BIN IN(3105933,3105983,3106033,3106183,3106233,3106333,3106383,3106433,3106483,3106533,3106583,3106633,3106683,3106733,3106783,3106833,3106883,3106933,3106983,3107033,3107083,3107133,3107183,3107233,3107283,3107333)
		    AND (TO_CHAR(DT_INCLUSAO::TIMESTAMP, 'YYYY-MM-DD') = '2018-10-03');
		COMMIT TRANSACTION ;
		ROLLBACK TRANSACTION ;

		-- ALTERA O HORARIO DA SESSAO DE JULGAMENTO NOS MOVIMENTOS (498 - 279ª Sessão Ordinária)
			BEGIN TRANSACTION ;
			   -- UPDATE CORE.TB_PROCESSO_EVENTO
			    SET DS_TEXTO_FINAL_EXTERNO = 'Incluído em pauta para 09/10/2018 14:00:00 Plenário.',
			        DS_TEXTO_FINAL_INTERNO = 'Incluído em pauta para 09/10/2018 14:00:00 Plenário.'
			    WHERE ID_PROCESSO_EVENTO IN(3255887,3255787,3255587,3255987,3255937,3255737,3255537,3255837,3255687,3255487,3255437,3255637);
			COMMIT TRANSACTION ;
			ROLLBACK TRANSACTION ;

			-- ALTERA O HORARIO DA SESSAO DE JULGAMENTO NOS DOCUMENTOS (498 - 279ª Sessão Ordinária)
			BEGIN TRANSACTION ;
			    UPDATE CORE.TB_PROCESSO_DOCUMENTO_BIN
			    SET DS_MODELO_DOCUMENTO = REPLACE(DS_MODELO_DOCUMENTO, '09-10-2018, &agrave;s 09:00.', '09-10-2018, &agrave;s 14:00.')
			    WHERE ID_PROCESSO_DOCUMENTO_BIN IN(3105733,3105383,3105333,3105633,3105483,3105433,3105683,3105583,3105533,3105783,3105833,3105283)
			    AND (TO_CHAR(DT_INCLUSAO::TIMESTAMP, 'YYYY-MM-DD HH24:MI') = '2018-10-03 17:10');
			COMMIT TRANSACTION ;
			ROLLBACK TRANSACTION ;	

	### [TAYNER] <LINK>

		### OBJETIVO
			> DEVE PERMITIR QUE O SISTEMA CADASTRE O USUARIO COMO PESSOA FISICA E COMO JUSPOSTULANDI

		### SCRIPT DE ANALISE
					/*
					OBJETIVO: 1 PERMITIR QUE O USUARIO SEJA CADASTRADO COMO PESSOA FISICA
					          2     
						
						NOME COMPLETO:             		WALTER FERRARI VÉRAS
						CPF:                       		556.377.606-91 
						DATA DE EXPEDIÇÃO CPF: 	    	24/04/2015
						NOME DA MÃE:               		LAURA FERRARI FARIAS 
						NATURALIDADE (CIDADE/ESTADO): 	MIRASSOL - SP 
						DATA DE NASCIMENTO:             09/01/1965
						TELEFONES (FIXO E CELULAR):     (11) 98165 1888
						ENDEREÇO COM CEP:  				RUA JOÃO CARBONARI JÚNIOR, 163 – CONDÔMINO DAS SERRAS – BL08 – AP72 – VILA NOVA JUNDIAÍNOPOLIS – JUNDIAÍ – SP CEP: 13210-705 
						E-MAIL ATUALIZADO:    			walter@agnusconsulting.com.br
				*/
				-- RECUPERAR TABELAS DO BANCO DE DADOS PELO NOME
				SELECT NSPNAME, RELNAME, ATTNAME
				FROM PG_NAMESPACE N, PG_CLASS C, PG_ATTRIBUTE A, PG_TYPE T
				WHERE N.OID = C.RELNAMESPACE
				AND C.RELKIND ILIKE 'R'
				AND A.ATTNUM > 0
				AND NOT A.ATTISDROPPED
				AND A.ATTRELID = C.OID
				AND A.ATTTYPID = T.OID
				AND A.ATTNAME ILIKE '%ESPECIALI%'
				ORDER BY NSPNAME, RELNAME, ATTNAME;

				BEGIN TRANSACTION;
					UPDATE ACL.TB_USUARIO_LOGIN SET DS_SENHA = '$2a$12$Xmr6b9QcSf/6uep1axnV9OV3UUI5yQHlNBRuKB/Et9VpqedzE25Ee', IN_STATUS_SENHA = 'A', DT_VALIDADE_SENHA = '2020-01-01'
					WHERE DS_LOGIN IN ('01547345195');
				COMMIT TRANSACTION;

				SELECT * FROM ACL.TB_USUARIO_LOGIN WHERE DS_LOGIN = '55637760691';
					
				-- APOS A PESQUISA POR NOME E CPF DE UM DETERMINADO USUARIO PELO SCRIPT DE UNIFICACAO DE UM DETERMINADO USUSARIO
				-- RECUPERAR DADOS DO USUARIO
				SELECT ID_USUARIO, DS_NOME, IN_ATIVO, DS_CERT_CHAIN_USUARIO, DT_VALIDADE_SENHA
				FROM TB_USUARIO_LOGIN 
				WHERE ID_USUARIO IN(24584,64805,78525,84044);

				-- LOCALIZAR O 'ID_PESSOA' COM O 'ID_USUARIO'
				SELECT ID_PESSOA_DOC_IDENTIFICACAO, CD_TP_DOCUMENTO_IDENTIFICACAO, NR_DOCUMENTO_IDENTIFICACAO, DS_NOME_USUARIO_LOGIN, DS_NOME_PESSOA

				SELECT *
				FROM TB_PESS_DOC_IDENTIFICACAO
				WHERE ID_PESSOA IN(24584, 64805, 78525, 84044);

				SELECT ID_USUARIO, ds_login, DS_NOME, IN_ATIVO, DS_CERT_CHAIN_USUARIO, DT_VALIDADE_SENHA
				FROM TB_USUARIO_LOGIN 
				WHERE ID_USUARIO IN(84044);

				SELECT * FROM TB_PESSOA WHERE id_pessoa = 84044;

				SELECT *
				FROM TB_CADASTRO_TEMP_PUSH
				WHERE DS_EMAIL ILIKE '%walter@%'; -- 19062234	556.377.606-91  walter@agnusconsulting.com.br

				SELECT *
				FROM CLIENT.TB_CADASTRO_TEMP_PUSH O
				WHERE O.nr_documento = '556.377.606-91'
				OR O.DS_EMAIL = 'walter@agnusconsulting.com.br';

				SELECT CADASTROTE0_.ID_CADASTRO_TEMP_PUSH AS ID1_121_, CADASTROTE0_.CD_HASH AS CD2_121_, CADASTROTE0_.IN_CONFIRMADO AS IN3_121_, CADASTROTE0_.DS_EMAIL AS DS4_121_, CADASTROTE0_.DT_EXPIRACAO AS DT5_121_, CADASTROTE0_.DT_INCLUSAO AS DT6_121_, CADASTROTE0_.NR_DOCUMENTO AS NR7_121_, CADASTROTE0_.CD_TIPO_DOC_IDENTIFICACAO AS CD8_121_
				FROM TB_CADASTRO_TEMP_PUSH CADASTROTE0_
				WHERE CADASTROTE0_.NR_DOCUMENTO =?
				OR CADASTROTE0_.DS_EMAIL =?

				SELECT *
				FROM TB_USUARIO_LOGIN
				WHERE ID_USUARIO = 84044;

				SELECT *
				FROM TB_USUARIO_LOGIN
				WHERE ds_email ILIKE '%walter@agnusconsulting.com.br%';

				-- DEVE-SE PESQUISAR ESSES USUARIOS NO PJE

				-- VERIFICAR EM QUAL PROCESSO UMA PESSOA FAZ PARTE.
				-- SE A PESSOA EM QUESSTAO E PARTE DE ALGUM PROCESSO NÃO DEVE SER EXCUIDA DO SISTEMA.
				SELECT *
				FROM CLIENT.TB_PROCESSO_PARTE
				WHERE ID_PESSOA = 84044;

				SELECT * 
				FROM TB_PESSOA_FISICA 
				WHERE ID_PESSOA_FISICA = 1;

				SELECT COUNT(ID_PESSOA_FISICA) FROM TB_PESSOA_FISICA;
				SELECT MAX(ID_PESSOA_FISICA) FROM TB_PESSOA_FISICA;
				SELECT * FROM TB_PESSOA_FISICA WHERE ID_PESSOA_FISICA = 84044;

				--DELETE 
				FROM TB_PESSOA_FISICA
				WHERE ID_PESSOA_FISICA = 84044;

				SELECT * FROM TB_PESSOA_AUTORIDADE WHERE ID_PESSOA_AUTORIDADE = 84044;
				SELECT * FROM TB_USUARIO WHERE id_usuario = 84044;
				SELECT * FROM TB_PESSOA WHERE id_pessoa = 84044;

				-- INSERT PARA RESOLUSAO NO CADASTRO DE PESSOA FISICA
				BEGIN TRANSACTION ;
					INSERT INTO CLIENT.TB_PESSOA_FISICA (ID_PESSOA_FISICA, ID_ETNIA, ID_ESTADO_CIVIL, ID_PROFISSAO, ID_ESCOLARIDADE, IN_SEXO, DT_NASCIMENTO, NM_GENITORA, NM_GENITOR, DT_OBITO, NR_DDD_CELULAR, NR_CELULAR, NR_DDD_TEL_RESIDENCIAL, NR_TEL_RESIDENCIAL, NR_DDD_TEL_COMERCIAL, NR_TEL_COMERCIAL, IN_INCAPAZ, ID_MUNICIPIO_NASCIMENTO, DT_VALIDACAO, IN_VALIDADO, DS_OUTRAS_CARACTERISTICAS, ID_PAIS, IN_BRASILEIRO, IN_ESPECIALIZACOES)
					VALUES(84044, NULL, NULL, NULL, NULL, 'M', '09/01/1965', 'LAURA FERRARI FARIAS', NULL, NULL, '11', '98165 1888', '  ', '', '  ', '', FALSE, NULL, NULL, NULL, NULL, NULL, TRUE, 0);
				COMMIT TRANSACTION ;

						NOME COMPLETO:             		WALTER FERRARI VÉRAS
						CPF:                       		556.377.606-91 
						DATA DE EXPEDIÇÃO CPF: 	    	24/04/2015
						NOME DA MÃE:               		LAURA FERRARI FARIAS 
						NATURALIDADE (CIDADE/ESTADO): 	MIRASSOL - SP 
						DATA DE NASCIMENTO:             09/01/1965
						TELEFONES (FIXO E CELULAR):     (11) 98165 1888
						ENDEREÇO COM CEP:  				RUA JOÃO CARBONARI JÚNIOR, 163 – CONDÔMINO DAS SERRAS – BL08 – AP72 – VILA NOVA JUNDIAÍNOPOLIS – JUNDIAÍ – SP CEP: 13210-705 
						E-MAIL ATUALIZADO:    			walter@agnusconsulting.com.br

				-- RETORNA TODOS OS PROCESSOS EM QEU UMA PARTE FAZ PARTE		
				--SELECT *
				SELECT DISTINCT ID_PESSOA_PARTE, NM_PESSOA_PARTE, B.NR_PROCESSO
				FROM TB_PROC_PARTE_EXPEDIENTE A
				INNER JOIN TB_PROCESSO B
				ON B.ID_PROCESSO = A.ID_PROCESSO_TRF
				WHERE ID_PESSOA_PARTE in(84044); -- 0004339-80.2010.2.00.0000

				SELECT *
				FROM TB_PROC_PARTE_EXPEDIENTE
				WHERE  ID_PESSOA_PARTE = 84044;

				SELECT * FROM TB_USUARIO_LOGIN WHERE ID_USUARIO = 84044;
				SELECT * FROM TB_USUARIO WHERE ID_USUARIO = 84044;
				SELECT * FROM TB_PESSOA WHERE ID_PESSOA = 84044;
				SELECT * FROM TB_PESSOA_AUTORIDADE WHERE ID_PESSOA_AUTORIDADE = 84044;
				SELECT * FROM TB_PESSOA_FISICA WHERE ID_PESSOA_FISICA = 84044;


				SELECT * FROM CORE.TB_PROCESSO WHERE ID_PROCESSO = 36087;

				SELECT * FROM TB_PROC_PARTE_EXPEDIENTE WHERE ID_PESSOA_PARTE = 84044;
				INSERT INTO client.tb_proc_parte_expediente
				(id_processo_parte_expediente, id_pessoa_parte, id_processo_expediente, dt_ciencia_parte, qt_prazo_legal_parte, dt_prazo_legal_parte, qt_prazo_processual_parte, dt_prazo_processual_parte, in_ciencia_sistema, id_pessoa_ciencia, nm_pessoa_parte, nm_pessoa_ciencia, in_pendente_manifestacao, id_resposta, ds_pendencia, in_fechado, in_tipo_prazo, id_processo_trf, ds_recibo_dje, in_intima_pessoal, id_procuradoria, in_destaque, cod_tipo_calc_meio_comunicacao)
				VALUES(88191, 84044, 88051, '18:36:18', 0, NULL, NULL, NULL, false, 84044, 'WALTER FERRARI VéRAS', 'WALTER FERRARI VéRAS', false, NULL, NULL, true, 'S', 36087, NULL, false, NULL, true, NULL);
				INSERT INTO client.tb_proc_parte_expediente
				(id_processo_parte_expediente, id_pessoa_parte, id_processo_expediente, dt_ciencia_parte, qt_prazo_legal_parte, dt_prazo_legal_parte, qt_prazo_processual_parte, dt_prazo_processual_parte, in_ciencia_sistema, id_pessoa_ciencia, nm_pessoa_parte, nm_pessoa_ciencia, in_pendente_manifestacao, id_resposta, ds_pendencia, in_fechado, in_tipo_prazo, id_processo_trf, ds_recibo_dje, in_intima_pessoal, id_procuradoria, in_destaque, cod_tipo_calc_meio_comunicacao)
				VALUES(88192, 84044, 88052, '14:59:00', 0, NULL, NULL, NULL, false, 84044, 'WALTER FERRARI VéRAS', 'WALTER FERRARI VéRAS', false, NULL, NULL, true, 'S', 36087, NULL, false, NULL, true, NULL);

				-- BREGA POINTS
				PreCadastroPessoaBean [line: 1501] - buscarDocumentoIdentificacao(String, String, Pais, Boolean, TipoPessoaEnum)
				PreCadastroPessoaBean [line: 1504] - buscarDocumentoIdentificacao(String, String, Pais, Boolean, TipoPessoaEnum)
				PreCadastroPessoaBean [entry] - buscarDocumentoIdentificacao(String, String, Pais, Boolean, TipoPessoaEnum)	

				SELECT *
				FROM TB_PESSOA_FISICA
				WHERE id_pessoa_fisica = 54517;

				SELECT *
				FROM TB_PESSOA_FISICA
				WHERE id_pessoa_fisica = 54517;

				SELECT *
				FROM TB_PESS_DOC_IDENTIFICACAO
				WHERE ID_PESSOA IN(54517);

				SELECT *
				FROM client.tb_pessoa_autoridade WHERE id_pessoa_autoridade = 54517;

				DELETE 
				FROM client.tb_pessoa_autoridade
				WHERE id_pessoa_autoridade = 54517;

				/*
					OBJETIVO: DESCRIÇÃO: ALTERAR USUARIO DE AUTORIDADE PARA FISICA
				*/

				SELECT * FROM TB_USUARIO_LOGIN WHERE ID_USUARIO = 54517;
				SELECT * FROM tb_usuario WHERE ID_USUARIO = 54517;
				SELECT * FROM tb_pessoa WHERE id_pessoa = 54517;
				SELECT * FROM tb_pessoa_autoridade;
				SELECT * FROM tb_pessoa_fisica;

				--DELETE 
				FROM TB_PESSOA_FISICA
				WHERE ID_PESSOA_FISICA = 54517;

				-- 
				BEGIN TRANSACTION;
					UPDATE ACL.TB_USUARIO_LOGIN
					SET DT_VALIDADE_SENHA = '2020-12-01'
					WHERE ID_USUARIO = 54517;
					
					UPDATE CORE.TB_USUARIO
					SET IN_BLOQUEIO = FALSE, 
					    IN_PROVISORIO = FALSE
					WHERE ID_USUARIO = 54517;
					
					UPDATE CLIENT.TB_PESSOA
					SET ID_TIPO_PESSOA = 3, 
					     IN_TIPO_PESSOA = 'F'
					WHERE ID_PESSOA = 54517;
					
					DELETE FROM CLIENT.TB_PESSOA_AUTORIDADE
					WHERE ID_PESSOA_AUTORIDADE = 54517;
					
					INSERT INTO CLIENT.TB_PESSOA_FISICA (ID_PESSOA_FISICA, IN_INCAPAZ, IN_BRASILEIRO, IN_ESPECIALIZACOES) 
					VALUES (54517, FALSE, TRUE, 0);
				COMMIT TRANSACTION;
				ROLLBACK TRANSACTION;













				/*
				OBJETIVO: ALTERAR CADASTRO DA TABELA DE PESSOA PUSH PARA A TABELA DE PESSOA FISICA.

					1 PESQUISAR SE EXISTE DUPLICIDADE
					2 INSERIR PESSOA FISICA
					3 ALTERAR CADASTRO DE PESSOA PARA PESSOA FISICA
					4 
				*/

				-- 
				SELECT * FROM TB_USUARIO_LOGIN WHERE ID_USUARIO = 84044;
				SELECT * FROM TB_USUARIO WHERE ID_USUARIO = 84044;
				SELECT * FROM TB_PESSOA WHERE ID_PESSOA = 84044;
				SELECT * FROM TB_PESS_DOC_IDENTIFICACAO WHERE ID_PESSOA = 84044; 
				SELECT * FROM TB_PESSOA_AUTORIDADE WHERE ID_PESSOA_AUTORIDADE = 84044;
				SELECT * FROM TB_PESSOA_FISICA WHERE ID_PESSOA_FISICA = 84044;
				SELECT * FROM TB_PESSOA_JURIDICA WHERE ID_PESSOA_JURIDICA = 84044;
				SELECT * FROM TB_PESSOA_PUSH WHERE ID_PESSOA_PUSH = 19062235;

				SELECT *
				FROM CLIENT.TB_CADASTRO_TEMP_PUSH O
				WHERE O.nr_documento = '556.377.606-91'
				OR O.DS_EMAIL = 'walter@agnusconsulting.com.br';

				-- 
				SELECT * FROM TB_PESSOA WHERE ID_PESSOA = 84044;
				-- INSERT INTO client.tb_pessoa
				-- (id_pessoa, id_tipo_pessoa, in_tipo_pessoa, in_atrai_competencia, in_classificado, in_pessoa_individualizada, in_estrangeiro, id_oj_inclusao, in_unificado)
				-- VALUES(84044, 2, 'J', false, false, true, false, NULL, false);

				SELECT * FROM TB_PESSOA_JURIDICA WHERE ID_PESSOA_JURIDICA = 84044;
				-- INSERT INTO client.tb_pessoa_juridica
				-- (id_pessoa_juridica, id_ramo_atividade, dt_abertura, dt_fim_atividade, nr_cpf_responsavel, nm_responsavel, in_orgao_publico, tp_prazo_expediente_automatico, nm_fantasia, tp_orgao_publico, vl_limite_rpv, in_matriz, id_pessoa_juridica_matriz)
				-- VALUES(84044, NULL, NULL, NULL, NULL, NULL, false, NULL, 'WALTER FERRARI VéRAS', NULL, NULL, true, NULL);

				SELECT * FROM TB_PESSOA_PUSH WHERE ID_PESSOA_PUSH = 19062235;
				INSERT INTO client.tb_pessoa_push
				(id_pessoa_push, ds_email, nr_cep, ds_endereco, ds_bairro, id_municipio, in_sexo, nr_ddd_telefone, nr_telefone, ds_senha, nr_endereco, ds_complemento, ds_nome, nr_documento, cd_tipo_doc_identificacao, id_cadastro_temp_push)
				VALUES(19062235, 'walter@agnusconsulting.com.br', '13210-705', 'Rua João Carbonari Júnior', 'Vila Nova Jundiainópolis', 4988, 'M', '11', '981651888', '$2a$12$u3naXgqLs.OMNIu6.PzYK.CfPt/FkWInOx9IA841WEJn/rsyoaTpW', '165', 'BL08 - AP72', 'Walter Ferrari Véras', '556.377.606-91', 'CPF', 19062234);

				-- INSERIR PESSOA FISICA
				BEGIN TRANSACTION;
					INSERT INTO CLIENT.TB_PESSOA_FISICA (ID_PESSOA_FISICA, IN_INCAPAZ, IN_BRASILEIRO, IN_ESPECIALIZACOES)
					VALUES (84044, FALSE, TRUE, 0);
				COMMIT TRANSACTION;

				-- ALTERAR TIPO DE PESSOA PARA PESSOA FISICA
				BEGIN TRANSACTION;
					-- UPDATE CLIENT.TB_PESSOA 
					SET ID_TIPO_PESSOA = 3, 
					    IN_TIPO_PESSOA = 'F'
					WHERE ID_PESSOA = 84044;
				COMMIT TRANSACTION;

				-- EXCLUI PESSOA JURIDICA
				BEGIN TRANSACTION;
					-- DELETE
					FROM TB_PESSOA_JURIDICA
					WHERE ID_PESSOA_JURIDICA = 84044;
				COMMIT TRANSACTION;

				--
				BEGIN TRANSACTION;
					-- DELETE FROM CLIENT.TB_PESSOA_PUSH 
					WHERE ID_PESSOA_PUSH = 19062235;
				COMMIT TRANSACTION;
				ROLLBACK TRANSACTION;

				-- BRACK POINTS
				CadastroUsuarioAction [line: 321] - finalizarCadastro()	
				EspecializacaoPessoaBean [line: 181] - especializarJusPostulandi(PessoaFisica)	
				PessoaService [line: 481] - desabilitarUsuarioPush(Pessoa)	
				PessoaService [line: 732] - tornaJusPostulandi(Pessoa)	
				PreCadastroPessoaBean [line: 1499] - buscarDocumentoIdentificacao(String, String, Pais, Boolean, TipoPessoaEnum)	
				CadastroUsuarioAction [entry] - alterarLocalizacaoAtualJusPostulandi()	
				PessoaService [entry] - desabilitarUsuarioPush(Pessoa)	
				PessoaService [entry] - tornaJusPostulandi(Pessoa)	
				UsuarioService [entry] - acrescentaLocalizacaoPessoal(String, Pessoa, Papel)
				PessoaService [line: 481] - desabilitarUsuarioPush(Pessoa)	
				CadastroTempPushDAO [entry] - recuperarCadastroTempPushByLogin(String)	


				-- DEFINITIVO
				BEGIN TRANSACTION;
					INSERT INTO CLIENT.TB_PESSOA_FISICA (ID_PESSOA_FISICA, IN_INCAPAZ, IN_BRASILEIRO, IN_ESPECIALIZACOES)
					VALUES (84044, FALSE, TRUE, 0);
				COMMIT TRANSACTION;

				BEGIN TRANSACTION;
					UPDATE CLIENT.TB_PESSOA 
					SET ID_TIPO_PESSOA = 3, 
					    IN_TIPO_PESSOA = 'F'
					WHERE ID_PESSOA = 84044;
				COMMIT TRANSACTION;

				BEGIN TRANSACTION;
					DELETE
					FROM TB_PESSOA_JURIDICA
					WHERE ID_PESSOA_JURIDICA = 84044;
				COMMIT TRANSACTION;

				BEGIN TRANSACTION;
					DELETE FROM CLIENT.TB_PESSOA_PUSH 
					WHERE ID_PESSOA_PUSH = 19062235;
				COMMIT TRANSACTION;
				ROLLBACK TRANSACTION;

		### SCRIPT DE CORRECAO

			-- INSERIR PESSOA FISICA
			BEGIN TRANSACTION;
				INSERT INTO CLIENT.TB_PESSOA_FISICA (ID_PESSOA_FISICA, IN_INCAPAZ, IN_BRASILEIRO, IN_ESPECIALIZACOES)
				VALUES (84044, FALSE, TRUE, 0);
			COMMIT TRANSACTION;

			-- ALTERAR TIPO DE PESSOA PARA PESSOA FISICA
			BEGIN TRANSACTION;
				UPDATE CLIENT.TB_PESSOA 
				SET ID_TIPO_PESSOA = 3, 
				    IN_TIPO_PESSOA = 'F'
				WHERE ID_PESSOA = 84044;
			COMMIT TRANSACTION;

			-- EXCLUI PESSOA JURIDICA
			BEGIN TRANSACTION;
				DELETE
				FROM TB_PESSOA_JURIDICA
				WHERE ID_PESSOA_JURIDICA = 84044;
			COMMIT TRANSACTION;

			--
			BEGIN TRANSACTION;
				DELETE FROM CLIENT.TB_PESSOA_PUSH 
				WHERE ID_PESSOA_PUSH = 19062235;
			COMMIT TRANSACTION;
			ROLLBACK TRANSACTION;

	### [DEMANDA-0000] <LINK>

		### OBJETIVO
			> 

		### SCRIPT DE ANALISE

		### SCRIPT DE CORRECAO

	### [DEMANDA-0000] <LINK>

		### OBJETIVO
			> 

		### SCRIPT DE ANALISE

		### SCRIPT DE CORRECAO