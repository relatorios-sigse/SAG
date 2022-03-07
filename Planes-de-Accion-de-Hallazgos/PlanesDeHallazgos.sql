SELECT
/**
Modificaciones:
2018-07-30 Se cambiaron las fechas fichas generadas por el BI para el campo ACTDEADLINE (plazo del plan de acción) por la función
TO_CHAR(sysdate,'YYYY-MM-DD'). 
2018-07-31. Inclusión de datos de acciones de plan.
2018-08-17. Exclusión en SQL de restricciones de seguridad del módulo Plan de Acción
2019-03-07. Ajuste de relación con tablas de hallazgos, ya que cliente reportó que algunos planes estaban asociados a hallazgos con los 
que realmente no hay relación
2019-08-16. Inclusión de identificador en campo 'Acc_Área del responsable'
---SE Suite 2.1-----
2020-08-20. Ajuste de relación planes de acción y hallazgos.
2020-09-04. Conversión de tipo para campos ACC_AREA_DEL_RESPONSABLE y NMCONCATe50d5144 (categoría del plan)
2020-09-14. Inclusión de dimensión para el identificador de plan de acción. GNACT.IDACTIVITY ID_PLAN_ACCION,
2021-09-22. Ajuste de medición ACC_ACCION para que signe 0 al avance de la acción cuando el campo esté nulo. Esto debido
a que SE hizo un ajuste en la regla del producto para que el avance se muestre nulo en el Analytics cuando no se haya informado ningún
avance en la acción. Antes se mostraba 0 en el Analytics.
**/


ACC.ACTDEADLINE ACC_PLAZO,
ACC.NMCASEFGSTATUS ACC_SITUACION,
ACC.NMCONCATb0b1bd3a ACC_ACCION,
ACC.NMCONCAT6a708c8a ACC_TIPO_ACCION,
CASE WHEN ACC.VLPERCENTAGEMFORMATED IS NULL THEN 0 ELSE ACC.VLPERCENTAGEMFORMATED END ACC_AVANCE,
ACC.NMCONCATf6f468bc ACC_PLAN_ASOCIADO,
ACC.DTSTARTPLAN  ACC_INI_PLA ,
ACC.DTFINISHPLAN ACC_FIN_PLA,
ACC.DTSTART  ACC_INI_REA,
ACC.DTFINISH  ACC_FIN_REA ,
ACC.NMUSER ACC_RESPONSABLE,
CAST(ACC.AREA_DEL_RESPONSABLE AS VARCHAR(255)) ACC_AREA_DEL_RESPONSABLE,
PLANES.*
FROM
(SELECT 


p.idprocess,
p.nmprocess,
hall.dsoccurrence,

                CASE 
                    
                    WHEN GNACT.FGSTATUS = 1 OR GNACT.FGSTATUS = 2
                        THEN
                            CASE 
                                WHEN
 (GNACT.DTSTARTPLAN IS NOT NULL 
 AND GNACT.DTSTARTPLAN < TO_DATE(TO_CHAR(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                    THEN 'Atrasado'
                                WHEN
 (GNACT.DTSTARTPLAN IS NULL OR GNACT.DTSTARTPLAN>=TO_DATE(TO_CHAR(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                    THEN 'Al día'
                            END
                    
                    WHEN GNACT.FGSTATUS = 3
                        THEN
                            CASE 
                                WHEN GNACT.DTSTART IS NULL 
 AND 1=2
                                    THEN
                                        CASE 
                                            WHEN
 (GNACT.DTSTARTPLAN < TO_DATE(TO_CHAR(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                                THEN 'Atrasado'
                                            WHEN
 (GNACT.DTSTARTPLAN > TO_DATE(TO_CHAR(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                            THEN 'Al día'
                                            Else 'Próximo del vencimiento'
                                        END
                                ELSE
                                    CASE 
                                        WHEN
 (GNACT.DTFINISHPLAN < TO_DATE(TO_CHAR(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                            THEN 'Atrasado'
                                        WHEN
 (GNACT.DTFINISHPLAN > TO_DATE(TO_CHAR(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                        THEN 'Al día'
                                        Else 'Próximo del vencimiento'
                                    END
                            END
                    
                    WHEN GNACT.FGSTATUS = 5 OR GNACT.FGSTATUS = 4
                        THEN
                            CASE 
                                WHEN
 (GNACT.DTSTARTPLAN IS NULL OR GNACT.DTFINISH <= GNACT.DTFINISHPLAN)
                                    THEN 'Al día'
                                ELSE
                                    'Atrasado'
                            END
                END
             AS ACTDEADLINE,        CAST(CASE
 WHEN GNACT.FGSTATUS = 1 THEN 'Planificación' 
 WHEN GNACT.FGSTATUS = 2 THEN 'Aprobación de planificación' 
 WHEN GNACT.FGSTATUS = 3 THEN 'Ejecución' 
 WHEN GNACT.FGSTATUS = 4 THEN 'Verificación de eficacia' 
 WHEN GNACT.FGSTATUS = 5 THEN 'Finalizado' 
 WHEN GNACT.FGSTATUS = 6 THEN 'Cancelado' 
 WHEN GNACT.FGSTATUS = 7 THEN 'Cancelado' 
 WHEN GNACT.FGSTATUS = 8 THEN 'Cancelado' 
 WHEN GNACT.FGSTATUS = 9 THEN 'Cancelado' 
 WHEN GNACT.FGSTATUS = 10 THEN 'Cancelado' 
 WHEN GNACT.FGSTATUS = 11 THEN 'Cancelado' 
END AS VARCHAR(255)) AS NMCASEFGSTATUS 
     , CAST(GNGNTP.IDGENTYPE || CASE WHEN GNGNTP.IDGENTYPE IS NULL THEN NULL ELSE ' - ' END || GNGNTP.NMGENTYPE AS VARCHAR(255)) AS NMCONCATe50d5144, CAST(GNACT.IDACTIVITY || CASE WHEN GNACT.IDACTIVITY IS NULL THEN NULL ELSE ' - ' END || GNACT.NMACTIVITY AS VARCHAR(510)) AS NMCONCATca4c9cd2,
                                 CASE
                                    WHEN GNACT.NRTASKSEQ = 1
                                    THEN '1 - Alta prioridad'
                                    WHEN GNACT.NRTASKSEQ = 2
                                    THEN '3 - Media prioridad'
                                    WHEN GNACT.NRTASKSEQ = 3
                                    THEN '5 - Baja prioridad'
                                    ELSE ''
                                 END NMPRIORITY,
                                 ADUSR.NMUSER       ,
				 (select d.iddepartment || ' - ' || d.nmdepartment from aduserdeptpos udp join addepartment d on d.cddepartment = udp.cddepartment where udp.fgdefaultdeptpos = 1 and udp.cduser = ADUSR.cduser) USER_DEPT,
				 (select p.idposition || ' - ' || p.nmposition from aduserdeptpos udp join adposition p on p.cdposition = udp.cdposition where udp.fgdefaultdeptpos = 1 and udp.cduser = ADUSR.cduser) USER_POS,
                                 ADUSR2.NMUSER AS NMUSERPLAN ,
                                 GNACT.DTSTARTPLAN  ,
                                 GNACT.DTFINISHPLAN ,
                                 GNACT.DTSTART      ,
                                 GNACT.DTFINISH,
                                 GNCOST.MNCOSTREAL,
                                 CAST(GNACT.VLPERCENTAGEM AS NUMBER(18,2)) AS VLPERCENTAGEMFORMATED,
					GNACT.CDGENACTIVITY,
 					GNACT.IDACTIVITY ID_PLAN_ACCION,
								 1 AS QT
                                 
FROM GNACTIVITY GNACT 
				INNER JOIN GNACTIONPLAN GNACPL ON
 (GNACPL.CDGENACTIVITY = GNACT.CDGENACTIVITY)

				INNER JOIN GNGENTYPE GNGNTP ON
 (GNGNTP.CDGENTYPE = GNACPL.CDACTIONPLANTYPE) 
				INNER JOIN ADUSER ADUSR ON
 (ADUSR.CDUSER = GNACT.CDUSERACTIVRESP)
				INNER JOIN ADUSER ADUSR2 ON
 (ADUSR2.CDUSER = GNACT.CDUSER) 

LEFT join GNASSOCACTIONPLAN GNASS on (GNACPL.CDGENACTIVITY = GNASS.CDACTIONPLAN ) 
LEFT join GNACTIVITY GNA on (GNA.CDASSOC = GNASS.CDASSOC)
LEFT join wfprocess p on (p.cdgenactivity = gna.cdgenactivity)
LEFT join inoccurrence hall on (hall.idworkflow = p.idobject) 

 LEFT OUTER JOIN GNCOSTCONFIG GNCOST ON
 (GNACT.CDCOSTCONFIG = GNCOST.CDCOSTCONFIG)
				 LEFT OUTER JOIN GNVWAPPROVRESP GNR1 ON
 (GNACT.CDPLANPRODROUTE = GNR1.CDPROD 
 AND GNACT.CDPLANROUTE = GNR1.CDAPPROV   AND
                       
 (
                           
 (GNR1.FGAPPROVRESP = 1 
 AND EXISTS
 (SELECT CDDEPARTMENT 
 FROM ADUSERDEPTPOS UDP1 
 WHERE UDP1.CDDEPARTMENT = GNR1.CDDEPARTMENT 
 AND UDP1.CDUSER = 831)) OR
                           
 (GNR1.FGAPPROVRESP = 2 
 AND EXISTS
 (SELECT UDP2.CDPOSITION 
 FROM ADUSERDEPTPOS UDP2  
 WHERE UDP2.CDPOSITION = GNR1.CDPOSITION 
 AND UDP2.CDUSER = 831)) OR
                           
 (GNR1.FGAPPROVRESP = 3 
 AND EXISTS
 (SELECT UDP3.CDPOSITION 
 FROM ADUSERDEPTPOS UDP3 
 WHERE UDP3.CDDEPARTMENT = GNR1.CDDEPARTMENT 
 AND UDP3.CDPOSITION = GNR1.CDPOSITION 
 AND UDP3.CDUSER = 831)) OR
                           
 (GNR1.FGAPPROVRESP = 4 
 AND GNR1.CDUSER = 831) OR
                           
 (
                                GNR1.FGAPPROVRESP = 5 
                                
 AND EXISTS
                               
 (
                                    SELECT  ATEA.CDUSER
                                    
 FROM    ADTEAMMEMBER ATEA
                                    
 WHERE  ATEA.CDTEAM = GNR1.CDTEAM 
										AND	(
                                               
 (ATEA.FGTEAMMEMBER = 1 
 AND EXISTS
 (SELECT ADPT.CDUSER 
 FROM ADUSERDEPTPOS ADPT 
 WHERE ADPT.CDDEPARTMENT = ATEA.CDDEPARTMENT 
 AND ADPT.CDUSER = 831))
												OR
 (ATEA.FGTEAMMEMBER = 2 
 AND EXISTS
 (SELECT ADPTOM.CDUSER 
 FROM ADUSERDEPTPOS ADPTOM 
 WHERE ADPTOM.CDPOSITION = ATEA.CDPOSITION 
 AND ADPTOM.CDUSER = 831))
												OR
 (ATEA.FGTEAMMEMBER = 3 
 AND EXISTS(SELECT  UDP4.CDDEPARTMENT, UDP4.CDPOSITION 
 FROM ADUSERDEPTPOS UDP4 
 WHERE UDP4.CDUSER = 831 
 AND UDP4.CDPOSITION = ATEA.CDPOSITION 
 AND UDP4.CDDEPARTMENT = ATEA.CDDEPARTMENT))
												OR
 (ATEA.FGTEAMMEMBER = 4 
 AND ATEA.CDUSER = 831)
                                            )
                                        
 AND ATEA.CDTEAM IN
 (GNR1.CDTEAM)
                                )
                            )
                            
                        )
                        
 AND GNR1.FGPEND = 1 )
				 LEFT OUTER JOIN GNVWAPPROVRESP GNR2 ON
 (GNACT.CDPRODROUTE = GNR2.CDPROD 
 AND GNACT.CDEXECROUTE = GNR2.CDAPPROV   AND
                       
 (
                           
 (GNR2.FGAPPROVRESP = 1 
 AND EXISTS
 (SELECT CDDEPARTMENT 
 FROM ADUSERDEPTPOS UDP1 
 WHERE UDP1.CDDEPARTMENT = GNR2.CDDEPARTMENT 
 AND UDP1.CDUSER = 831)) OR
                           
 (GNR2.FGAPPROVRESP = 2 
 AND EXISTS
 (SELECT UDP2.CDPOSITION 
 FROM ADUSERDEPTPOS UDP2  
 WHERE UDP2.CDPOSITION = GNR2.CDPOSITION 
 AND UDP2.CDUSER = 831)) OR
                           
 (GNR2.FGAPPROVRESP = 3 
 AND EXISTS
 (SELECT UDP3.CDPOSITION 
 FROM ADUSERDEPTPOS UDP3 
 WHERE UDP3.CDDEPARTMENT = GNR2.CDDEPARTMENT 
 AND UDP3.CDPOSITION = GNR2.CDPOSITION 
 AND UDP3.CDUSER = 831)) OR
                           
 (GNR2.FGAPPROVRESP = 4 
 AND GNR2.CDUSER = 831) OR
                           
 (
                                GNR2.FGAPPROVRESP = 5 
                                
 AND EXISTS
                               
 (
                                    SELECT  ATEA.CDUSER
                                    
 FROM    ADTEAMMEMBER ATEA
                                    
 WHERE  ATEA.CDTEAM = GNR2.CDTEAM 
										AND	(
                                               
 (ATEA.FGTEAMMEMBER = 1 
 AND EXISTS
 (SELECT ADPT.CDUSER 
 FROM ADUSERDEPTPOS ADPT 
 WHERE ADPT.CDDEPARTMENT = ATEA.CDDEPARTMENT 
 AND ADPT.CDUSER = 831))
												OR
 (ATEA.FGTEAMMEMBER = 2 
 AND EXISTS
 (SELECT ADPTOM.CDUSER 
 FROM ADUSERDEPTPOS ADPTOM 
 WHERE ADPTOM.CDPOSITION = ATEA.CDPOSITION 
 AND ADPTOM.CDUSER = 831))
												OR
 (ATEA.FGTEAMMEMBER = 3 
 AND EXISTS(SELECT  UDP4.CDDEPARTMENT, UDP4.CDPOSITION 
 FROM ADUSERDEPTPOS UDP4 
 WHERE UDP4.CDUSER = 831 
 AND UDP4.CDPOSITION = ATEA.CDPOSITION 
 AND UDP4.CDDEPARTMENT = ATEA.CDDEPARTMENT))
												OR
 (ATEA.FGTEAMMEMBER = 4 
 AND ATEA.CDUSER = 831)
                                            )
                                        
 AND ATEA.CDTEAM IN
 (GNR2.CDTEAM)
                                )
                            )
                            
                        )
                        
 AND GNR2.FGPEND = 1 ) 
 WHERE GNACPL.FGMODEL = 2 ) PLANES
LEFT JOIN 
(SELECT 
                CASE 
                    
                    WHEN GNACT.FGSTATUS = 1 OR GNACT.FGSTATUS = 2
                        THEN
                            CASE 
                                WHEN
 (GNACT.DTSTARTPLAN IS NOT NULL 
 AND GNACT.DTSTARTPLAN < TO_DATE(TO_CHAR(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                    THEN 'Atrasado'
                                WHEN
 (GNACT.DTSTARTPLAN IS NULL OR GNACT.DTSTARTPLAN>=TO_DATE(TO_CHAR(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                    THEN 'Al día'
                            END
                    
                    WHEN GNACT.FGSTATUS = 3
                        THEN
                            CASE 
                                WHEN GNACT.DTSTART IS NULL 
 AND 1=2
                                    THEN
                                        CASE 
                                            WHEN
 (GNACT.DTSTARTPLAN < TO_DATE(TO_CHAR(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                                THEN 'Atrasado'
                                            WHEN
 (GNACT.DTSTARTPLAN > TO_DATE(TO_CHAR(sysdate+2,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                            THEN 'Al día'
                                            Else 'Próximo del vencimiento'
                                        END
                                ELSE
                                    CASE 
                                        WHEN
 (GNACT.DTFINISHPLAN < TO_DATE(TO_CHAR(sysdate,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                            THEN 'Atrasado'
                                        WHEN
 (GNACT.DTFINISHPLAN > TO_DATE(TO_CHAR(sysdate+2,'YYYY-MM-DD'),'YYYY-MM-DD'))
                                        THEN 'Al día'
                                        Else 'Próximo del vencimiento'
                                    END
                            END
                    
                    WHEN GNACT.FGSTATUS = 5 OR GNACT.FGSTATUS = 4
                        THEN
                            CASE 
                                WHEN
 (GNACT.DTSTARTPLAN IS NULL OR GNACT.DTFINISH <= GNACT.DTFINISHPLAN)
                                    THEN 'Al día'
                                ELSE
                                    'Atrasado'
                            END
                END
             AS ACTDEADLINE,   CAST(CASE
 WHEN GNACT.FGSTATUS = 1 THEN 'Planificación' 
 WHEN GNACT.FGSTATUS = 2 THEN 'Aprobación de planificación' 
 WHEN GNACT.FGSTATUS = 3 THEN 'Ejecución' 
 WHEN GNACT.FGSTATUS = 4 THEN 'Aprobación de ejecución' 
 WHEN GNACT.FGSTATUS = 5 THEN 'Finalizado' 
 WHEN GNACT.FGSTATUS = 6 THEN 'Cancelado' 
 WHEN GNACT.FGSTATUS = 7 THEN 'Cancelado' 
 WHEN GNACT.FGSTATUS = 8 THEN 'Cancelado' 
 WHEN GNACT.FGSTATUS = 9 THEN 'Cancelado' 
 WHEN GNACT.FGSTATUS = 10 THEN 'Cancelado' 
 WHEN GNACT.FGSTATUS = 11 THEN 'Cancelado' 
END AS VARCHAR(255)) AS NMCASEFGSTATUS 
     , CAST(GNGNTP.IDGENTYPE || CASE WHEN GNGNTP.IDGENTYPE IS NULL THEN NULL ELSE ' - ' END || GNGNTP.NMGENTYPE AS VARCHAR(510)) AS NMCONCAT6a708c8a, CAST(GNACT.IDACTIVITY || CASE WHEN GNACT.IDACTIVITY IS NULL THEN NULL ELSE ' - ' END || GNACT.NMACTIVITY AS VARCHAR(510)) AS NMCONCATb0b1bd3a,
                            ADUSR.NMUSER       ,
                            GNACT.DTSTARTPLAN  ,
                            GNACT.DTFINISHPLAN ,
                            GNACT.DTSTART      ,
                            GNACT.DTFINISH     ,
                            GNCOST.MNCOSTREAL,
                            CAST(GNACT.VLPERCENTAGEM AS NUMBER(18,2)) AS VLPERCENTAGEMFORMATED, CAST(GNACT2.IDACTIVITY || CASE WHEN GNACT2.IDACTIVITY IS NULL THEN NULL ELSE ' - ' END || GNACT2.NMACTIVITY AS VARCHAR(510)) AS NMCONCATf6f468bc,
                            CASE
                               WHEN GNACT2.NRTASKSEQ = 1
                               THEN '1 - Alta prioridad'
                               WHEN GNACT2.NRTASKSEQ = 2
                               THEN '3 - Media prioridad'
                               WHEN GNACT2.NRTASKSEQ = 3
                               THEN '5 - Baja prioridad'
                               ELSE ''
                            END NMPRIORITY,
				GNACT2.CDGENACTIVITY,
				ADDEPAR.IDDEPARTMENT || ' - ' || ADDEPAR.NMDEPARTMENT AREA_DEL_RESPONSABLE,
							1 AS QT	 
 
 FROM GNACTIVITY GNACT  
                                    INNER JOIN GNTASK GNTK ON
 (GNACT.CDGENACTIVITY = GNTK.CDGENACTIVITY)  
                                    LEFT OUTER JOIN GNTASKTYPE GNTKTP ON
 (GNTKTP.CDTASKTYPE = GNTK.CDTASKTYPE)  
                                    LEFT OUTER JOIN GNGENTYPE GNGNTP ON
 (GNGNTP.CDGENTYPE = GNTKTP.CDTASKTYPE)  
                                    INNER JOIN ADUSER ADUSR ON
 (ADUSR.CDUSER = GNACT.CDUSER)  
                                    LEFT OUTER JOIN ADUSER ADUSR2 ON
 (ADUSR2.CDUSER = GNACT.CDUSERACTIVRESP)  
                                    LEFT OUTER JOIN ADUSERDEPTPOS ADDEP ON
 (ADUSR.CDUSER = ADDEP.CDUSER 
 AND ADDEP.FGDEFAULTDEPTPOS = 1)  
                                    LEFT OUTER JOIN ADDEPARTMENT ADDEPAR ON
 (ADDEPAR.CDDEPARTMENT = ADDEP.CDDEPARTMENT)  
                                    LEFT OUTER JOIN ADPOSITION ADPOS ON
 (ADPOS.CDPOSITION = ADDEP.CDPOSITION)  
                                    LEFT OUTER JOIN GNACTIVITY GNACT2 ON
 (GNACT2.CDGENACTIVITY = GNACT.CDACTIVITYOWNER)  
                                    LEFT OUTER JOIN GNACTIONPLAN GNACPL ON
 (GNACPL.CDGENACTIVITY = GNACT2.CDGENACTIVITY)
                                    LEFT OUTER JOIN GNCOSTCONFIG GNCOST ON
 (GNACT.CDCOSTCONFIG = GNCOST.CDCOSTCONFIG)
                                    LEFT OUTER JOIN GNVWAPPROVRESP GNR1 ON
 (GNACT.CDPLANPRODROUTE = GNR1.CDPROD 
 AND GNACT.CDPLANROUTE = GNR1.CDAPPROV   AND
                       
 (
                           
 (GNR1.FGAPPROVRESP = 1 
 AND EXISTS
 (SELECT CDDEPARTMENT 
 FROM ADUSERDEPTPOS UDP1 
 WHERE UDP1.CDDEPARTMENT = GNR1.CDDEPARTMENT 
 AND UDP1.CDUSER = 831)) OR
                           
 (GNR1.FGAPPROVRESP = 2 
 AND EXISTS
 (SELECT UDP2.CDPOSITION 
 FROM ADUSERDEPTPOS UDP2  
 WHERE UDP2.CDPOSITION = GNR1.CDPOSITION 
 AND UDP2.CDUSER = 831)) OR
                           
 (GNR1.FGAPPROVRESP = 3 
 AND EXISTS
 (SELECT UDP3.CDPOSITION 
 FROM ADUSERDEPTPOS UDP3 
 WHERE UDP3.CDDEPARTMENT = GNR1.CDDEPARTMENT 
 AND UDP3.CDPOSITION = GNR1.CDPOSITION 
 AND UDP3.CDUSER = 831)) OR
                           
 (GNR1.FGAPPROVRESP = 4 
 AND GNR1.CDUSER = 831) OR
                           
 (
                                GNR1.FGAPPROVRESP = 5 
                                
 AND EXISTS
                               
 (
                                    SELECT  ATEA.CDUSER
                                    
 FROM    ADTEAMMEMBER ATEA
                                    
 WHERE  ATEA.CDTEAM = GNR1.CDTEAM 
										AND	(
                                               
 (ATEA.FGTEAMMEMBER = 1 
 AND EXISTS
 (SELECT ADPT.CDUSER 
 FROM ADUSERDEPTPOS ADPT 
 WHERE ADPT.CDDEPARTMENT = ATEA.CDDEPARTMENT 
 AND ADPT.CDUSER = 831))
												OR
 (ATEA.FGTEAMMEMBER = 2 
 AND EXISTS
 (SELECT ADPTOM.CDUSER 
 FROM ADUSERDEPTPOS ADPTOM 
 WHERE ADPTOM.CDPOSITION = ATEA.CDPOSITION 
 AND ADPTOM.CDUSER = 831))
												OR
 (ATEA.FGTEAMMEMBER = 3 
 AND EXISTS(SELECT  UDP4.CDDEPARTMENT, UDP4.CDPOSITION 
 FROM ADUSERDEPTPOS UDP4 
 WHERE UDP4.CDUSER = 831 
 AND UDP4.CDPOSITION = ATEA.CDPOSITION 
 AND UDP4.CDDEPARTMENT = ATEA.CDDEPARTMENT))
												OR
 (ATEA.FGTEAMMEMBER = 4 
 AND ATEA.CDUSER = 831)
                                            )
                                        
 AND ATEA.CDTEAM IN
 (GNR1.CDTEAM)
                                )
                            )
                            
                        )
                        
 AND GNR1.FGPEND = 1 ) 
                                   ) ACC ON ACC.CDGENACTIVITY = PLANES.CDGENACTIVITY