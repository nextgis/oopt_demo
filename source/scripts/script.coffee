#   SETTINGS

settings ={
    home: [85, 60, 10000000.0]
    baseMap_ru: "tile_run-bike-hike",
    baseMap_en: "tile_run-bike-hike",
    dataPath: "data/",
    layerPath: "ndata/"
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

isAnimate = false;
viewer.camera.moveStart.addEventListener(() ->
    isAnimate = true
)
viewer.camera.moveEnd.addEventListener(() ->
    isAnimate = false
)

resetDefaultRenderLoop = () ->
    viewer.useDefaultRenderLoop = false

stopRendering = () ->
    resetDefaultRenderLoop()
    

startRendering = () ->
    if !viewer.useDefaultRenderLoop
        viewer.useDefaultRenderLoop = true

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



# BUILD ABOUT INFO
build_about = ()->
    about_url = {"en": "about.html", "ru": "about_ru.html"}[lang]
    $.ajax({
        url: about_url,
        dataType : "html",
        success: (data, textStatus)->
            $(".copyright__info__inner").html(data)
            $(".about__cesium-credit").append($(".cesium-viewer-bottom").detach())
        error: ()->
            $(".copyright__info__inner").empty()
    })
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
        fly_to_Russia()
        commandInfo.cancel = true
)

fly_to_Russia = ()->
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
load_np = ()->
    dataSource = new Cesium.GeoJsonDataSource()
    dataSource.load(settings.layerPath + "np.topojson", {clampToGround: true}).then( ()->
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
        load_zp()
    )
load_np()

load_zp = ()->
    dataSource = new Cesium.GeoJsonDataSource()
    dataSource.load(settings.layerPath + "zp.topojson", {clampToGround: true}).then( ()->
        viewer.dataSources.add(dataSource)

        entities = dataSource.entities.values
        mat_property = new Cesium.ColorMaterialProperty(new Cesium.Color.fromCssColorString('rgba(105,131,40, .87)'))
        for entity in entities
            if entity.polygon
                entity.polygon.material = mat_property
                entity.polygon.outline = new Cesium.ConstantProperty(false)
                entity.isNP = false
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

        if oopt[entity_key][0].isNP
            color = new Cesium.Color.fromCssColorString('#d8b366')
            $(".left_menu div:last-child").addClass('np')
        else
            $(".left_menu div:last-child").addClass('zp')
            color = new Cesium.Color.fromCssColorString('#7ab342')

        rect = get_oopt_rect(entity_key)

        center = Cesium.Rectangle.center(rect)
        center = [center.latitude, center.longitude]
        if entity_key == 'Ostrov Vrangelya'
            center = [rect.north, rect.east]


        oopt[entity_key].center = center

        billboards.add({
            image : 'images/white-pin.png',
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
    border_source.load(settings.layerPath + 'russia-bnd.topojson', {clampToGround: true}).then( ()->

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
                        color: Cesium.ColorGeometryInstanceAttribute.fromColor(new Cesium.Color.fromCssColorString('rgba(45,25,15, .33)'))
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
    load_popups_data()


load_popups_data = ()->
    $.getJSON(settings.dataPath + 'data.json', (data)->
        popups_data =  data.data
    )




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
    scene.camera.flyTo({
        destination: Cesium.Cartesian3.fromDegrees(settings.home[0], settings.home[1], settings.home[2]),
        duration: 3
    });
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

$('.popup_menu .info').on('click', (e)->
    open_popup($('.popup .info'))
    startRendering()
)

is_video_enable = true
$('.popup_menu .video').on('click', (e)->
    if is_video_enable
        open_popup($('.popup .video'))
        stopRendering()
)

is_photo_enable = true
$('.popup_menu .photo').on('click', (e)->
    startRendering()
    if is_photo_enable
        open_popup($('.popup .photo'))

)

#$('.popup_menu .web').on('click', (e)->
#    open_popup($('.popup .web'))
#)





#
#       O P E N   M E N U
#


open_menu = ()->
    startRendering()
    selected_id = oopt[selected_polygon_name]._id
    prepare_popup(selected_id)

    $('.popup_menu').stop()
    $('.popup_menu').animate({bottom:"15%"}, 2000)
#    $('.menu_op_name').text(selected_polygon_name)

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
    startRendering()
    $('.left_menu div').removeClass('selected_item')
    $('.popup_menu').stop()
    $('.popup_menu').animate({bottom:"-30%"}, 500)
    $('.popup').hide()

    for element in oopt[selected_polygon_name]
        element.polygon.outline  = new Cesium.ConstantProperty(false)
        element.polygon.outlineColor  = new Cesium.ColorMaterialProperty( new Cesium.Color(1, 1, 1, 0) )


$(document).on('click', ()->
    $(".copyright__info__close").click()
    $('.close_popup').click()
    if selected_polygon_name != ""
        close_menu())

open_popup = (target)->
    $('.popup:hidden').fadeIn()
    $('.popup__panel').hide()
    if (!$('video')[0].paused)
        $('video')[0].pause()
    target.show()
    if (target.find("video").length)
        target.find("video")[0].currentTime = 0
        target.find("video")[0].play()

$('.close_popup').on('click', (e)->
    startRendering()
    $('.popup').hide()
    if (!$('video')[0].paused)
        $('video')[0].pause()
    e.stopPropagation()
)


#    PHOTO GALLERY
showed_image = 1
num_images = 0

$('.photos_left').on('click', (e)->
    e.stopPropagation()
    showed_image--
    if showed_image <= 0 then showed_image = num_images
    $('.photo_container img').hide()
    $('.photo_container img').eq(showed_image).fadeIn()
    $('.photo_caption span').hide()
    $('.photo_caption span').eq(showed_image).fadeIn()
)

$('.photos_right').on('click', (e)->
    e.stopPropagation()
    showed_image++
    if showed_image > num_images then showed_image = 1
    $('.photo_container img').hide()
    $('.photo_container img').eq(showed_image).fadeIn()
    $('.photo_caption span').hide()
    $('.photo_caption span').eq(showed_image).fadeIn()
)

$('.popup').on('click', (e)->
    e.stopPropagation()
)

# PREPARE POPUP
prepare_popup = (_id)->
    current_popup_data = {}
    for dta in popups_data
        if dta.id == _id then current_popup_data = dta

#    ВОТ ТУТ ЗАКОМЕНИТЬ
#    current_popup_data = popups_data[0]


    second_name =  if (oopt[selected_polygon_name][0].isNP) then {"en": "National Park", "ru": "Национальный парк"}[lang] else {"en": "Zapovednik", "ru": "Заповедник"}[lang]
    $('.popup h2').text(selected_polygon_name+" "+second_name)
    $('.menu_op_name').text(selected_polygon_name).append( $('<div class="small-header"></div>').text(second_name) )

    build_gallery(current_popup_data.images, current_popup_data.id, current_popup_data.captions)
    build_info(current_popup_data.id)
    build_video(current_popup_data.id)
    #build_web(current_popup_data.url)



build_gallery = (_num_images, folder_name, captions)->
    $('.photo_container img').remove()

    is_photo_enable = true
    $('.popup_menu .photo').css('opacity', 1)
    $('.popup_menu .photo').text({"en": "Photo", "ru": "Фото"}[lang])

    if _num_images == 0
        is_photo_enable = false
        $('.popup_menu .photo').css('opacity', 0.5)
        $('.popup_menu .photo').text({"en": "No Photo", "ru": "Нет Фото"}[lang])


    $('.photo_container').append( $('<img>').attr('src', settings.dataPath + folder_name + '/photo/'+ _num_images + '.jpg') )
    $('.photo_caption').append($('<span />'))
    for i in [1.._num_images]
        $('.photo_container').append( $('<img>').attr('src', settings.dataPath + folder_name + '/photo/' + i + '.jpg') )
        if captions && captions[i-1]
            $('.photo_caption').append($('<span />').html(captions[i-1][lang]))
    $('.photo_container').append( $('<img>').attr('src', settings.dataPath + folder_name + '/photo/1.jpg') )
    $('.photo_container img').fadeOut(50)
    $('.photo_caption span').fadeOut(50);
    $('.photo_container img').eq(showed_image).fadeIn(50)
    $('.photo_caption span').eq(showed_image).fadeIn(50)
    num_images = _num_images

build_info = (_id)->
    info_url = {"en": settings.dataPath + _id + "/index.html", "ru": settings.dataPath + _id + "/index_ru.html"}[lang]
    $.ajax({
        url: info_url,
        dataType : "html",
        success: (data, textStatus)->
            $(".popup__panel.info").html(data)
        error: ()->
            $(".popup__panel.info").empty()
    })

build_web = (url)->
    $('.web iframe').attr('src', url)


build_video = (_id)->
    is_video_enable = true

    $('.popup_menu .video').css('opacity', 1)
    $('.popup_menu .video').text({"en": "Video", "ru": "Видео"}[lang])
    video_parent = $('.popup__panel.video')
    $('video').remove()
    video_parent.append('<video class="popup__panel__inner"></video>')
    $('video').attr('src', settings.dataPath + _id+'/video/video_1.mp4')
    $('video').attr('preload','metadata')
    $('video').attr('controls','true')


    $("video").on("error", ()->
          $('.popup_menu .video').css('opacity', 0.5)
          $('.popup_menu .video').text({"en": "No Video", "ru": "Нет Видео"}[lang])
    )

