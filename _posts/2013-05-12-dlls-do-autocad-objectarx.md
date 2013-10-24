---
layout: post
title: "DLLs do AutoCAD ObjectArx"
category: posts
author: brunosaboia
tags: [ Autocad, ObjectArx ]
---

Olá a todos.

Esse post visa tentar explicar um pouco sobre cada DLL do AutoCAD ObjectARX, que é nosso arcabouço de objetos que nos permite interagir com o programa (aliás, o ObjectARX é indispensável para o acompanhamento desse blog, se você ainda não fez, faça o download [aqui](http://usa.autodesk.com/adsk/servlet/index?id=773204&siteID=123112)).

Enfim, se olharmos os arquivos do ObjectARX (neste caso, estamos analisando especificamente a versão 2013 do Framework), na pasta \inc, temos alguns arquivos *Mgd.dll. Eles são:

- AcCoreMgd.dll (esta DLL só existe a partir da versão 2013)
- AcDbMdg.dll
- AcMgd.dll
- AcTcMgd.dll

Se visualizarmos essas DLLs com o Object Browser, veremos o seguinte:

![Fig. 1: AcCoreMgd.dll]({{ site_url }}/images/dlls-do-autocad-objectarx.img1.png)

O nome da DLL já da uma dica do que se trata. O "core", isto é, o "coração" da API Managed do AutoCAD está contido nessa DLL. Existem alguns namespaces de interoperabilidade com o Editor, seviço de plotting, e de conexão com o Windows. Em suma, esta DLL é bastante importante e quase todos os nossos exemplos farão uso desta DLL (inclusive porque é ela que nos possibilita criar comandos com o atributo [CommandMethod]).

![Fig. 2: AcDbMgd.dll]({{ site_url }}/images/dlls-do-autocad-objectarx.img2.png)

Esta DLL é a que trata do banco de dados do AutoCAD, bem como os componentes que vão ser inseridos nela. É outra DLL crucial: se quisermos desenhar ou obter qualquer informação sobre o desenho, necessariamente precisaremos usar a AcDbMgd. Se examinarmos os namespaces, veremos os itens Geometry, que contém as classes Point, Line, etc., usadas para criar a geometria em memória, e DatabaseServices, que contém classes também de suma importância, tais quais Drawable e DBObject. A maioria das aplicação não as utilizam, mas como iremos desenhar bastante e mostrar o desenho na tela, elas serão muito utilizadas por nós.

![Fig. 3: AcMgd.dll]({{ site_url }}/images/dlls-do-autocad-objectarx.img3.png)
Outra biblioteca fundamental. Possui o namespace ApplicationServices, importante por ter, dentre outros, o DocumentManager. É com ele que iremos executar várias funções importantes relacionadas aos documentos no AutoCAD.

![Fig. 4: AcTcMgd.dll]({{ site_url }}/images/dlls-do-autocad-objectarx.img4.png)
Por último, a biblioteca AcTcMgd. Não é uma biblioteca fundamental, e dificilmente iremos utiliza-la no blog.
