#   SETTINGS
geodata = [
    { name: "np", path: "ndata/dv/np-dv.topojson", color: "#d8b366"},
    { name: "zp", path: "ndata/dv/zp-dv.topojson", color: "#7ab342"}
]

settings ={
    home: [147, 60, 6000000.0]
    baseMap_ru: "kosmo",
    baseMap_en: "tile_run-bike-hike",
    dataPath: "data/",
    layerPath: "ndata/dv/"
}

viewer = new Cesium.Viewer('cesiumContainer',
    {
        timeline: false,
        baseLayerPicker: false,
        infoBox: false,
        navigationHelpButton: false,
        geocoder: false,
        animation: false,
        scene3DOnly: true,
        fullscreenButton: false,
        imageryProvider: Cesium.createOpenStreetMapImageryProvider({
          url: {"en": settings.baseMap_en, "ru": settings.baseMap_ru}[lang],
          maximumLevel: 10
        })
    }
)

#   MAPS TILE
#osm = new Cesium.OpenStreetMapImageryProvider({
#    maximumLevel : 500,
#});
##osm_map = viewer.scene.imageryLayers.addImageryProvider( osm )
#
#bing = new Cesium.BingMapsImageryProvider({
#    url : 'http://dev.virtualearth.net',
#    key : 'Ail9PAst_7-T0BfqYAZjK4fVngfHJ3Fjg_ckK6eX8ro_xXwH2HcYUr_cJVDanhTV',
#    maximumLevel : 500,
#    mapStyle : Cesium.BingMapsStyle.AERIAL_WITH_LABELS
#});
#bing_map = viewer.scene.imageryLayers.addImageryProvider( bing )

insertByAjax = (url, container, callback)->
    $.ajax({
        url: url,
        dataType : "html",
        success: (data, textStatus)->
            container.html(data)
            if callback
                callback()
        error: ()->
            container.empty()
    })

# BUILD ABOUT INFO
build_about = ()->
    about_url = {"en": "about.html", "ru": "about_ru.html"}[lang]
    insertByAjax(about_url, $(".copyright__info__inner"), ()->
        $(".about__cesium-credit").append($(".cesium-viewer-bottom").detach())
    )
    $(".copyright__info-link").on("click", (e)->
        e.stopPropagation()
        e.preventDefault()
        $(".copyright__info").fadeToggle(100)
    )

    $(".copyright__info__close").on("click", (e)->
        e.preventDefault()
        $(".copyright__info").fadeOut(100)
    )

    $(".copyright__info").on("click", (e)->
        e.stopPropagation()
    )
   
build_about()

#   NORTH POLE CIRCLE
circleGeometry = new Cesium.CircleGeometry({
    center : Cesium.Cartesian3.fromDegrees(90.0, 90.0),
    radius : 560000.0,
    vertexFormat : Cesium.PerInstanceColorAppearance.VERTEX_FORMAT
})



redCircleInstance = new Cesium.GeometryInstance({
    geometry : circleGeometry,
    attributes : {
        color : Cesium.ColorGeometryInstanceAttribute.fromColor(new Cesium.Color(0.71, 0.816, 0.816, 1))
    }
})

pole_primitive = new Cesium.Primitive({
    geometryInstances: [redCircleInstance],
    appearance: new Cesium.PerInstanceColorAppearance({
        closed: true
    })
})
pole_primitive.show = false
viewer.scene.primitives.add(pole_primitive)





scene = viewer.scene;
primitives = scene.primitives;
oopt = {}

popups_data = []
current_popup_data = {}

selected_polygon_name = ''

#   FULLSCREEN
$('.fullscreen_btn').click(()->
    if $.fullscreen.isFullScreen()
        $.fullscreen.exit()
    else
        $('body').fullscreen();
    return false
);



#   HOME BUTTON OVERRIDE
viewer.homeButton.viewModel.command.beforeExecute.addEventListener(
    (commandInfo)->
        fly_to_home()
        commandInfo.cancel = true
)

fly_to_home = ()->
    scene.camera.flyTo({
        destination: Cesium.Cartesian3.fromDegrees(settings.home[0], settings.home[1], settings.home[2]),
        duration: 3
    })

#   CAMERA ON RUSSIAN AT START
scene.camera.flyTo({
    destination: Cesium.Cartesian3.fromDegrees(settings.home[0], settings.home[1], settings.home[2]),
    duration: 0
});


#    DATA LOADER
load_popups_data = ()->
    $.getJSON(settings.dataPath + 'data.json', (data)->
        popups_data =  data.data
    )
load_popups_data()

load_geodata =()->
    for data_item in geodata
        dataSource = new Cesium.GeoJsonDataSource()
        dataSource.load(data_item.path).then( ()->
            viewer.dataSources.add(dataSource)

            entities = dataSource.entities.values
            mat_property = new Cesium.ColorMaterialProperty( new Cesium.Color.fromCssColorString('rgba(208,177,125, .87)') );
            for entity in entities
                if entity.polygon
                    entity.polygon.material = mat_property;
                    entity.polygon.outline = new Cesium.ConstantProperty(false);
                    entity.isNP = true
                    if !oopt[entity.properties["Name_" + lang]]
                        oopt[entity.properties["Name_" + lang]] = []
                    oopt[entity.properties["Name_" + lang]].push(entity)
                    oopt[entity.properties["Name_" + lang]]._id = entity.properties.ids_ID

            load_zp()
        )
    
load_np = ()->
    dataSource = new Cesium.GeoJsonDataSource()
    dataSource.load(settings.layerPath + "np-dv.topojson", {clampToGround: true}).then( ()->
        viewer.dataSources.add(dataSource)

        entities = dataSource.entities.values
        mat_property = new Cesium.ColorMaterialProperty( new Cesium.Color.fromCssColorString('rgba(185, 132, 121,.87)') );
        for entity in entities
            if entity.polygon
                entity.polygon.material = mat_property;
                entity.polygon.outline = new Cesium.ConstantProperty(false);
                entity.isNP = true
                if !oopt[entity.properties["Name_" + lang]]
                    oopt[entity.properties["Name_" + lang]] = []
                oopt[entity.properties["Name_" + lang]].push(entity)
                oopt[entity.properties["Name_" + lang]]._id = entity.properties.ids_ID

        load_fz()
    )
load_np()

load_fz = ()->
    dataSource = new Cesium.GeoJsonDataSource()
    dataSource.load(settings.layerPath + "fz-dv.topojson", {clampToGround: true}).then( ()->
        viewer.dataSources.add(dataSource)

        entities = dataSource.entities.values        
        mat_property = new Cesium.ColorMaterialProperty( new Cesium.Color.fromCssColorString('rgba(208,177,125, .87)') );
        for entity in entities
            if entity.polygon
                entity.polygon.material = mat_property;
                entity.polygon.outline = new Cesium.ConstantProperty(false);
                entity.isFZ = true
                if !oopt[entity.properties["Name_" + lang]]
                    oopt[entity.properties["Name_" + lang]] = []
                oopt[entity.properties["Name_" + lang]].push(entity)
                oopt[entity.properties["Name_" + lang]]._id = entity.properties.ids_ID

        load_zp()
    )

load_zp = ()->
    dataSource = new Cesium.GeoJsonDataSource()
    dataSource.load(settings.layerPath + "zp-dv.topojson", {clampToGround: true}).then( ()->
        viewer.dataSources.add(dataSource)

        entities = dataSource.entities.values
        mat_property = new Cesium.ColorMaterialProperty(new Cesium.Color.fromCssColorString('rgba(105,131,40, .87)'))
        for entity in entities
            if entity.polygon
                entity.polygon.material = mat_property
                entity.polygon.outline = new Cesium.ConstantProperty(false)
                entity.isZP = true
                if !oopt[entity.properties["Name_" + lang]]
                    oopt[entity.properties["Name_" + lang]] = []
                oopt[entity.properties["Name_" + lang]].push(entity)
                oopt[entity.properties["Name_" + lang]]._id = entity.properties.ids_ID
                # console.log entity.properties.ids_ID

        build_pups()
    )

build_pups = ()->
    billboards = scene.primitives.add(new Cesium.BillboardCollection())

    keys = []
    for key of oopt
        keys.push(key)
    keys = keys.sort()


    for entity_key in keys

        withInvest = false
        for dta in popups_data
            if (dta.id == "" + oopt[entity_key]._id) && (dta.invest)
                withInvest = true

        $(".left_menu").append('<div>')
        $(".left_menu div:last-child").text(entity_key).on('click', (e)->
            $('.popup').hide()
            text = $(this).text()
            rect = get_oopt_rect(text)
            scene.camera.flyTo({destination: rect})
            selected_polygon_name = text
            setTimeout(open_menu, 100)
            e.stopPropagation()
        )

        if withInvest
           $(".left_menu div:last-child").addClass("left_menu__item--invest").append("<i class='left_menu__item__icon icon-attach_money'></i>")

        if oopt[entity_key][0].isNP
            color = new Cesium.Color.fromCssColorString('#a66d61')
            $(".left_menu div:last-child").addClass('np')
        if oopt[entity_key][0].isZP
            color = new Cesium.Color.fromCssColorString('#7ab342')            
            $(".left_menu div:last-child").addClass('zp')

        if oopt[entity_key][0].isFZ
            color = new Cesium.Color.fromCssColorString('#d8b366')
            $(".left_menu div:last-child").addClass('fz')

        rect = get_oopt_rect(entity_key)

        center = Cesium.Rectangle.center(rect)
        center = [center.latitude, center.longitude]

        oopt[entity_key].center = center

        billboards.add({
            image : 'images/pin.png',
            position : Cesium.Cartesian3.fromRadians(center[1], center[0], 20000),
            horizontalOrigin : Cesium.HorizontalOrigin.Center,
            verticalOrigin : Cesium.VerticalOrigin.BOTTOM,
            id: entity_key,
            color : color,
            translucencyByDistance : new Cesium.NearFarScalar(1500000, 0, 1600000, 1)
            scaleByDistance : new Cesium.NearFarScalar(1.5e2, 1.5, 1.5e7, 0.75),
        })

    load_borders()


load_borders = ()->
    border_source = new Cesium.GeoJsonDataSource()
    border_source.load(settings.layerPath + 'federal_dv.topojson', {clampToGround: true}).then( ()->

        b_entities = border_source.entities.values;

        for b_entitiy in b_entities
            positions =  b_entitiy.polygon.hierarchy.getValue().positions

            primitives.add(new Cesium.Primitive({
                geometryInstances : new Cesium.GeometryInstance({
                    geometry : new Cesium.PolylineGeometry({
                        positions : positions,
                        width : 1.0,
                        vertexFormat : Cesium.PolylineColorAppearance.VERTEX_FORMAT
                    }),
                    attributes: {
                        color: Cesium.ColorGeometryInstanceAttribute.fromColor(new Cesium.Color.fromCssColorString('rgba(153,153,153, .67)'))
                    }
                }),
                appearance : new Cesium.PolylineColorAppearance()
            }))

    load_cities()
    )


load_cities = ()->

#    labels = new Cesium.LabelCollection()
#    for city in cities
#        coord = city['coordinates']
#        name = city['name']
#        labels.add({
#            position : Cesium.Cartesian3.fromDegrees(coord[0], coord[1]),
#            text     : "◉ "+name,
#            font      : '12px Helvetica'
#        });
#    scene.primitives.add(labels);



#    CLICK HANDLER
handler = new Cesium.ScreenSpaceEventHandler(scene.canvas)
ellipsoid = scene.globe.ellipsoid

handler.setInputAction( ( (movement)->
    if selected_polygon_name != "" then close_menu()
    polygon = scene.drillPick(movement.position)[0]
    if polygon
        if (typeof polygon.id) == "string"
            polygon_name = polygon.id
        else
            polygon_name = polygon.id.properties["Name_" + lang]
        selected_polygon_name = polygon_name

        rect = get_oopt_rect(polygon_name)
        scene.camera.flyTo({destination: rect})
        selected_polygon_name = polygon_name
        setTimeout(open_menu, 100)

), Cesium.ScreenSpaceEventType.LEFT_CLICK )


get_oopt_rect = (name)->

    _points = [];

    for polygon in oopt[name]
        _points = _points.concat( polygon.polygon.hierarchy.getValue().positions )

    cartographics = Cesium.Ellipsoid.WGS84.cartesianArrayToCartographicArray( _points );
    cartographics = cartographics.filter( (val) ->
        return val.height == 0
    )
    rect = Cesium.Rectangle.fromCartographicArray(cartographics)

    rect.south -= Math.abs(rect.south-rect.north)*0.6
    rect.north += Math.abs(rect.south-rect.north)*0.1
    return rect


cities = [
    {
        "coordinates": [37.61325, 55.748],
        "name": "Moscow"
    },
    {
        "coordinates": [73.35733, 54.91536],
        "name": "Omsk"
    },
    {
        "coordinates": [104.18426, 52.19257],
        "name": "Irkutsk"
    },
    {
        "coordinates": [134.85471, 48.5309],
        "name": "Khabarovsk"
    },
]

#    HOME BTN CLICK
$('.home_btn').on('click', ()->
    fly_to_home()
)


$('.map_selector').on('click', (e)->
    if e.offsetX > 177/2
#        bing
        bing_map.alpha = 1
        osm_map.alpha = 0
        pole_primitive.show = false
        $('.map_selector_fader').transition({ x: 0 }, 100, 'ease');
    else
#        osm
        osm_map.alpha = 1
        bing_map.alpha = 0
        pole_primitive.show = true
        $('.map_selector_fader').transition({ x: -93 }, 100, 'ease');

    e.stopPropagation()
)



#   MENU CLICK HANDLERS

$('.popup_menu').on('click', (e)->
    e.stopPropagation()
)

$("[data-target]").on('click', (e)->
    e.preventDefault()
    if (!$(this).hasClass("disabled"))
        open_popup($(this).data("target"))
)

#
#       O P E N   M E N U
#

check_buttons = ()->
    $('[data-target = photo], [data-target = video], [data-target = route], [data-target = investment]').removeClass("disabled")

    if current_popup_data.images == 0
        $('[data-target = photo]').addClass("disabled")

    if !current_popup_data.video
          $('[data-target = video]').addClass("disabled")

    if !current_popup_data.route
          $('[data-target = route]').addClass("disabled")

    if !current_popup_data.invest
          $('[data-target = investment]').addClass("disabled")

open_menu = ()->
    selected_id = oopt[selected_polygon_name]._id
    prepare_popup(selected_id)

    $('.info-panel').removeClass("info-panel--hidden")

    for element in oopt[selected_polygon_name]
        element.polygon.outline  = new Cesium.ConstantProperty(true)
        element.polygon.outlineColor  = new Cesium.ColorMaterialProperty( new Cesium.Color(1, 1, 1, 1) )

#   Подсветить в левом меню

    $('.left_menu div').each(()->
        $(this).removeClass('selected_item')
        if( $(this).text() == selected_polygon_name )
            $(this).addClass('selected_item')
    )

close_menu = ()->
    $('.left_menu div').removeClass('selected_item')
    $('.info-panel').addClass("info-panel--hidden")
    close_popup()
    current_popup_data = {}

    for element in oopt[selected_polygon_name]
        element.polygon.outline  = new Cesium.ConstantProperty(false)
        element.polygon.outlineColor  = new Cesium.ColorMaterialProperty( new Cesium.Color(1, 1, 1, 0) )


$(document).on('click', ()->
    $(".copyright__info__close").click()
    if selected_polygon_name != ""
        close_menu())

open_popup = (target)->
    targetPanel = $(".popup__panel--" + target)
    $('.popup:hidden').show()
    $('.popup__panel').hide()

    $(".popup__subtitle--invest").hide()
    $(".popup__subtitle--routes").hide()

    if (!$('video')[0].paused)
        $('video')[0].pause()

    targetPanel.show()
    targetPanel.scrollTop(0)

    if (target == "video")
        $('video')[0].play()

    if (target == "photo")
        dataImg = get_img(current_popup_data.id, "photo", current_popup_data.images)
        build_gallery(dataImg, $(".photo-gallery"))

    if (target == "route")
        build_routes(current_popup_data.id)

    if (target == "investment")
        build_investment(current_popup_data.id)

close_popup = ()->    
    $('.popup').fadeOut()
    if (!$('video')[0].paused)
        $('video')[0].pause()
    $(".popup__subtitle--invest").hide()
    $(".popup__subtitle--routes").hide()

$('.close_popup').on('click', (e)->
    close_popup()
    e.preventDefault()
)

$('.popup').on('click', (e)->
    e.stopPropagation()
)

# PREPARE POPUP
prepare_popup = (_id)->
    current_popup_data = {}
    for dta in popups_data
        if dta.id == "" + _id then current_popup_data = dta

    check_buttons()

    if (oopt[selected_polygon_name][0].isNP)
        second_name = {"en": "National Park", "ru": "Национальный парк"}[lang]
    if (oopt[selected_polygon_name][0].isZP)
        second_name = {"en": "Nature Reserve", "ru": "Заповедник"}[lang]
    if (oopt[selected_polygon_name][0].isFZ)
        second_name = {"en": "Federal reserve", "ru": "Заказник"}[lang]
    $('.popup__title').text(selected_polygon_name+" "+second_name)
    $('.info-panel__title').text(selected_polygon_name)
    $('.info-panel__subtitle').text(second_name)

    build_info(current_popup_data.id)

    if current_popup_data.video
        build_video(current_popup_data.id)

get_img = (id, folder, num) ->
    images = []
    for i in [1..num]
        images.push( {img : settings.dataPath + id + '/' + folder + '/' + i + '.jpg'} )
    return images

build_gallery = (dataImg, container)->    
    if dataImg.length != 0
        if (dataImg.length==1) 
            container.addClass("fotorama--one-image")
        else
            container.removeClass("fotorama--one-image")

        fotorama = container.data("fotorama")

        if (fotorama)
            fotorama.show(0)
            fotorama.load(dataImg)
        else
            container.fotorama({
                data: dataImg
            })
            fotorama = container.data("fotorama")

build_info = (_id)->
    info_url = {"en": settings.dataPath + _id + "/index.html", "ru": settings.dataPath + _id + "/index_ru.html"}[lang]
    insertByAjax(info_url, $(".popup__panel--info"))

build_routes = (_id)->
    $(".popup__subtitle--routes").show()
    route_url = {"en": settings.dataPath + _id + "/routes.html", "ru": settings.dataPath + _id + "/routes_ru.html"}[lang]
    insertByAjax(route_url, $(".popup__panel--route .popup__panel__text"))
    dataImg = get_img(current_popup_data.id, "photo_route", current_popup_data.route_images)
    build_gallery(dataImg, $(".routes-gallery"))

build_investment = (_id)->
    $(".popup__subtitle--invest").show()
    investment_url = {"en": settings.dataPath + _id + "/invest.html", "ru": settings.dataPath + _id + "/invest_ru.html"}[lang]
    insertByAjax(investment_url, $(".popup__panel--investment .popup__panel__text"))
    dataImg = get_img(current_popup_data.id, "photo_invest", current_popup_data.invest_images)
    build_gallery(dataImg, $(".invest-gallery"))

build_video = (_id)->
    video_parent = $('video').parent()
    $('video').remove()
    video_parent.append('<video></video>')
    $('video').attr('src', settings.dataPath + _id + '/video/1.mov')
    $('video').attr('src-mp4', settings.dataPath + _id + '/video/1.mp4')
    $('video').attr('preload','metadata')
    $('video').attr('controls','true')

    $("video").on("error", ()->
      if $('video').attr('src') != $('video').attr('src-mp4')
          $('video').attr('src', $('video').attr('src-mp4'))
    )
