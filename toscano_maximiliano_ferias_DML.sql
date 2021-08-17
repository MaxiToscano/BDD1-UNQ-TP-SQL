

----------------------------------------EJERCICIO 2: CONSULTAS----------------------------------------

--Este archivo contiene puntos que eran DML los cuales estan al final del archivo.


--PUNTO 1. Obtenga el nombre y apellido de los usuarios que no están relacionados con ninguna feria ordenados por nombre.

SELECT id, nombre, apellido 
FROM "user"
WHERE id NOT IN ( 
                SELECT DISTINCT user_id  
                FROM user_feria
                )
ORDER BY nombre
;



--PUNTO 2. Obtenga el nombre y apellido de los usuarios que están relacionados con SOLAMENTE 1 feria ordenados por apellido.

SELECT id, nombre, apellido 
FROM "user" u
JOIN 
    (SELECT user_id, count(*)
     FROM user_feria
     GROUP BY user_id 
     HAVING count(*) = 1) AS user_fiel_1feria
ON u.id = user_fiel_1feria.user_id 
ORDER BY apellido
;



--PUNTO 3. Obtenga el nombre y apellido de los usuarios que no están relacionados con más de una feria.

--Entiendo que pide los usuarios que no están relacionados con ninguna feria mas los que se relacionan solamente con una.

SELECT id, nombre, apellido 
FROM "user"
WHERE id NOT IN ( 
                 SELECT DISTINCT user_id  
                 FROM user_feria)
OR id IN (  
          SELECT id
          FROM "user" u
          JOIN 
              (SELECT user_id, count(*)
               FROM user_feria
               GROUP BY user_id 
               HAVING count(*) = 1) AS u1f
          ON u.id = u1f.user_id)
ORDER BY id
;



/*PUNTO 4. Obtenga el precio por kilo promediado por mes de cada producto, ordenados por tipo de producto ascendente,
por especie y variedad del mismo y por precio por kilo descendente.*/

SELECT p.id, pt.nombre AS tipo_producto, especie, variedad, mes, prom_precio_kilo
FROM producto_tipo pt 
JOIN producto p
ON pt.id = p.tipo_id
JOIN (SELECT producto_declarado_id, EXTRACT (MONTH FROM fecha) AS mes, avg (precio_por_bulto/peso_por_bulto) AS prom_precio_kilo
      FROM declaracion_individual
      GROUP BY producto_declarado_id, mes) AS ppkm
ON p.id = ppkm.producto_declarado_id
ORDER BY tipo_producto ASC, especie, variedad, prom_precio_kilo desc
;


--PUNTO 5. Seleccione qué ferias están registradas pero no tienen ninguna declaración.

SELECT id, nombre 
FROM feria 
WHERE id NOT IN (
                 SELECT DISTINCT feria_id
                 FROM declaracion)
;



/*PUNTO 6. Seleccione el nombre, apellido y correo electrónico de los usuarios que 
hicieron declaraciones de ferias con las que no están relacionados.*/

SELECT id, nombre, apellido, email 
FROM "user" 
WHERE id IN (
             SELECT DISTINCT user_id 
             FROM user_feria uf 
             JOIN declaracion d
             ON uf.user_id = d.user_autor_id AND uf.feria_id <> d.feria_id) --declaraciones sin relacion 
;



--PUNTO 7. Selecciones aquellas frutas cuyo precio promedio por kilo histórico no supere los 50 pesos.

SELECT id, especie, prom_precio_kilo_hist
FROM producto p 
JOIN (
      SELECT producto_declarado_id, avg (precio_por_bulto/peso_por_bulto) AS prom_precio_kilo_hist
      FROM declaracion_individual
      GROUP BY producto_declarado_id
      HAVING avg (precio_por_bulto/peso_por_bulto) <= 50) AS ppkh
ON p.id = ppkh.producto_declarado_id
WHERE tipo_id IN (
                  SELECT id
                  FROM producto_tipo 
                  WHERE nombre = 'Fruta')
;



/*PUNTO 8. Obtenga, ordenados alfabéticamente, el nombre y apellido de los usuarios que sólo 
frutas tienen en sus declaraciones (de acuerdo al tipo de producto).*/


SELECT id, nombre, apellido
FROM "user"  
WHERE id IN (
             SELECT DISTINCT user_autor_id
             FROM declaracion)  
AND id NOT IN 
             (SELECT DISTINCT d.user_autor_id 
              FROM declaracion d
              JOIN declaracion_individual di
              ON d.id = di.declaracion_id
              JOIN producto p 
              ON di.producto_declarado_id = p.id
              WHERE p.tipo_id IN 
                                 (SELECT id 
                                  FROM producto_tipo 
                                  WHERE nombre <> 'Fruta'))            
ORDER BY nombre
;

/*Esta consulta da vacia ya que no hay usuarios que hayan declarado solamente frutas.
Para probar el resultado inserté registros que cumplan con la condición de la consulta 
para el ultimo usuario agregado del punto F "Ines Cosa"

INSERT INTO declaracion (id, fecha_generacion, user_autor_id, feria_id)
VALUES (49, '2020-06-29', 101, 3);

INSERT INTO declaracion_individual (id, producto_declarado_id, declaracion_id, fecha)
VALUES (815, 1, 49, '2020-06-29');
*/



--PUNTO 9. Obtenga un listado que muestre la cantidad de ferias por zona, ordenados descendentemente por cantidad.

SELECT zona, count(*) AS cant_ferias 
FROM feria
WHERE zona IS NOT NULL 
GROUP BY zona 
ORDER BY cant_ferias desc
;



/*PUNTO 10. Obtenga un listado que muestre la cantidad de ferias por zona, ordenados 
descendentemente (el listado debe excluir a las ferias sin declaraciones).*/


SELECT zona, count(*) AS cant_ferias 
FROM feria
WHERE zona IS NOT NULL 
AND id IN (
           SELECT DISTINCT feria_id
           FROM declaracion)
GROUP BY zona
ORDER BY cant_ferias desc
;



/*PUNTO 11. Obtenga un listado que muestre la cantidad de ferias por zona, ordenados descendentemente 
(el listado debe incluir a las ferias sin declaraciones). 

Así como está expresada la consigna se resolveria con la misma consulta del punto 9 ya que ahi estan todas las ferias.*/

SELECT zona, count(*) AS cant_ferias 
FROM feria
WHERE zona IS NOT NULL 
GROUP BY zona 
ORDER BY cant_ferias desc
;

--En el caso que pidiera el listado de cantidad ferias por zonas contando solamente las que no tienen declaraciones.*/

SELECT zona, count(*) AS cant_ferias 
FROM feria
WHERE zona IS NOT NULL 
AND id NOT IN (
               SELECT DISTINCT feria_id
               FROM declaracion)
GROUP BY zona
ORDER BY cant_ferias desc
;



/*PUNTO 12. Obtenga un listado que muestre, de cada localidad donde haya usuarios registrados, el promedio de kilos por bulto, 
el máximo de kilos por bulto y el mínimo de kilos por bulto de naranjas ofrecidos en ferias de ese distrito.*/


SELECT localidad, avg (peso_por_bulto) AS prom_peso_bulto_naranja, max (peso_por_bulto) AS max_peso_naranja, min (peso_por_bulto) AS min_peso_naranja
FROM feria f
JOIN declaracion d
ON f.id = d.feria_id
JOIN (
      SELECT declaracion_id, peso_por_bulto
      FROM declaracion_individual  
      WHERE producto_declarado_id IN (           
                                      SELECT id 
                                      FROM producto 
                                      WHERE especie ILIKE 'naranja')) AS peso_naranja 
ON d.id = peso_naranja.declaracion_id                                                 
WHERE f.id IN (                                                                        
               SELECT DISTINCT feria_id
               FROM user_feria)
GROUP BY localidad
;

/*Uso ILIKE porque en la tabla producto hay productos escritos con minuscúla y otros con mayúculas
 y en el caso que hubiese: 'naranja','NARANJA' o 'Naranja' los tome a todos.
Habia querido implementar un COLLATE con terminacion "CI_AI" (por lo que encontré sirve para que en las consultas
no distinga entre mayúsculas, minúsculas o acentos) pero no pude hacerlo de las diferentes formas que probé */



--PUNTO 15. Obtenga un listado con el precio promedio, precios máximos y mínimo por producto en la semana actual.

SELECT producto_declarado_id, avg (precio_por_bulto) AS prom_precio_semana_actual, max (precio_por_bulto) AS max_precio_semana_actual, min (precio_por_bulto) AS min_precio_semana_actual
FROM declaracion_individual 
WHERE EXTRACT (week FROM fecha) = EXTRACT (week FROM current_date)
GROUP BY producto_declarado_id 
;



--PUNTO 16. Obtenga el precio promedio por producto y por zona en la semana anterior a la actual.


SELECT producto_declarado_id, zona, avg (precio_por_bulto) AS prom_precio_producto_zona 
FROM declaracion_individual di 
JOIN 
    (SELECT d.id, zona 
     FROM declaracion d 
     JOIN feria f 
     ON d.feria_id = f.id) AS df
ON di.declaracion_id = df.id
WHERE EXTRACT (week FROM fecha) = EXTRACT (week FROM current_date) - 1
GROUP BY producto_declarado_id, zona 
;



/*PUNTO 18. Obtenga las 3 ferias con más usuarios que no hayan hecho declaraciones o que sólo las hayan hecho en
ferias con menos de 50 puestos.*/


SELECT feria_id, count (*) AS cantidad_usuarios
FROM user_feria 
WHERE user_id NOT IN (
                      SELECT DISTINCT user_autor_id
                      FROM declaracion)
OR user_id IN (
               SELECT user_autor_id
               FROM declaracion d
               JOIN feria f 
               ON d.feria_id = f.id
               WHERE cantidad_puestos < 50)
GROUP BY feria_id 
ORDER BY count (*) DESC
LIMIT 3
;



------------------------------LOS SIGUENTES PUNTOS SON DDL------------------------------


/*PUNTO 13. En la tabla de productos conocemos su PK, pero es necesario impedir que pueda 
repetirse especie y variedad. Explique cómo lo haría e impleméntelo.*/

/*Para impedir que se repitan valores de atributos no clave estableceria una restrición UNIQUE en la 
la tabla que quiera hacerlo y para los campos deseados. En este caso para la tabla producto en los 
los campos especie y variedad. Lo implementaria de la siguiente manera antes de insertar valores en la tabla: */

ALTER TABLE producto 
ADD CONSTRAINT no_repetir_especie_variedad --nombre de la restricción
UNIQUE (especie, variedad)
;

/*Para poder implementarlo tuve que modificar algunos registros del archivo de datos de la tabla producto donde 
en los campos especie y variedad se repetia papa negra y así me permitiera la restricción UNIQUE.
Yo lo hice modificando directamente el archivo de datos, si habia que hacerlo con comandos hubiese buscado los registros 
con SELECT Y WHERE donde para especie y variedad tenga los valores 'papa''negra' para ver los id de productos que hacia falta 
modificar y despues con UPDATE, SET y WHERE hubiese modificados los valores en algún o ambos campos para esos id. 
O si no habia problema los borraba con DELETE FROM producto WHERE especie = 'papa' AND variedad = 'negra'
*/




/*PUNTO 14. Cree una vista (view) con la información de correo del usuario, nombre, ubicación de todas las ferias con
las que está relacionado. Dicho listado debe incluir a los usuarios que no tienen ferias asociadas.*/

CREATE VIEW vista_user_ferias_ubicacion AS 
SELECT email, nombre AS user_nombre, localidad AS ubicacion_feria_relacionada
FROM "user" u
LEFT JOIN (
           SELECT user_id, localidad, domicilio
           FROM user_feria uf 
           JOIN feria f 
           ON uf.feria_id = f.id) AS info_ferias
ON u.id = info_ferias.User_id
ORDER BY ubicacion_feria_relacionada
;

--SELECT * FROM vista_user_ferias_ubicacion;
--Al final de la vista con valores null en el últmimo campo se muestran los usuarios que no tienen ferias asociadas.



/*PUNTO 17. Con el uso del sistema se identificaron muchísimas consultas buscando productos por 
su especie y variedad en la condición, cree un índice adecuado para dicha búsqueda.*/

CREATE INDEX indice_productos_especie_variedad 
ON producto (especie, variedad)
;
