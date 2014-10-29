#   SETTINGS

viewer = new Cesium.Viewer('cesiumContainer',
    {
        timeline: false,
        baseLayerPicker: false,
        infoBox: false,
        navigationHelpButton: false,
        geocoder: false,
        animation: false,
        scene3DOnly: true,
        fullscreenButton: false
    }
)

#   MAPS TILE
osm = new Cesium.OpenStreetMapImageryProvider({
    maximumLevel : 500,
});
osm_map = viewer.scene.imageryLayers.addImageryProvider( osm )

bing = new Cesium.BingMapsImageryProvider({
    url : 'http://dev.virtualearth.net',
    mapStyle : Cesium.BingMapsStyle.AERIAL,
    tilingScheme: new Cesium.GeographicTilingScheme()
});
bing_map = viewer.scene.imageryLayers.addImageryProvider( bing )



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

selected_polygon_name = ''

#   SCENE RESIZE

resize = ()->
    $('#cesiumContainer').css('width', parseInt($(document).width())-200+'px')

resize()
$(window).on('resize', resize)



#   HOME BUTTON OVERRIDE
viewer.homeButton.viewModel.command.beforeExecute.addEventListener(
    (commandInfo)->
        fly_to_Russia()
        commandInfo.cancel = true
)

fly_to_Russia = ()->
    scene.camera.flyTo({
        destination: Cesium.Cartesian3.fromDegrees(85, 60, 10000000.0),
        duration: 3
    })

#   CAMERA ON RUSSIAN AT START
scene.camera.flyTo({
    destination: Cesium.Cartesian3.fromDegrees(85, 60, 10000000.0),
    duration: 0
});


#    DATA LOADER
load_np = ()->
    dataSource = new Cesium.GeoJsonDataSource()
    dataSource.loadUrl("ndata/np-bcc.topojson").then( ()->
        viewer.dataSources.add(dataSource)

        entities = dataSource.entities.entities
        mat_property = Cesium.ColorMaterialProperty.fromColor( new Cesium.Color(0, 0.3, 0.9, 0.6) );
        for entity in entities
            if entity.polygon
                entity.polygon.material = mat_property;
                entity.polygon.outline = new Cesium.ConstantProperty(false);
                entity.isNP = true
                if !oopt[entity.properties.NAME_EN]
                    oopt[entity.properties.NAME_EN] = []
                oopt[entity.properties.NAME_EN].push(entity)

        load_zp()
    )
load_np()

load_zp = ()->
    dataSource = new Cesium.GeoJsonDataSource()
    dataSource.loadUrl("ndata/zp-bcc.topojson").then( ()->
        viewer.dataSources.add(dataSource)

        entities = dataSource.entities.entities
        mat_property = Cesium.ColorMaterialProperty.fromColor( new Cesium.Color(0, 0.9, 0.3, 0.6) )
        for entity in entities
            if entity.polygon
                entity.polygon.material = mat_property
                entity.polygon.outline = new Cesium.ConstantProperty(false)
                entity.isNP = false
                if !oopt[entity.properties.NAME_EN]
                    oopt[entity.properties.NAME_EN] = []
                oopt[entity.properties.NAME_EN].push(entity)

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
            text = $(this).text()
            rect = get_oopt_rect(text)
            scene.camera.flyToRectangle({destination: rect})
            setTimeout(open_menu, 100)
            e.stopPropagation()

        )

        if oopt[entity_key][0].isNP
            color = new Cesium.Color(0, 0.3, 0.9, 1)
            $(".left_menu div:last-child").addClass('np')
        else
            $(".left_menu div:last-child").addClass('zp')
            color = new Cesium.Color(0, 0.9, 0.3, 1)

        rect = get_oopt_rect(entity_key)

        center = Cesium.Rectangle.center(rect)
        center = [center.latitude, center.longitude]
        if entity_key == 'Ostrov Vrangelya'
            center = [rect.north, rect.east]


        oopt[entity_key].center = center

        billboards.add({
            image : 'images/dot.png',
            position : Cesium.Cartesian3.fromRadians(center[1], center[0], 20000),
            id: entity_key,
            color : color,
            translucencyByDistance : new Cesium.NearFarScalar(1200000, 0, 1300000, 1)
        })

    load_borders()


load_borders = ()->
    border_source = new Cesium.GeoJsonDataSource()
    border_source.loadUrl('ndata/russia-bnd.topojson').then( ()->

        b_entities = border_source.entities.entities;

        for b_entitiy in b_entities
            positions =  b_entitiy.polygon.positions.getValue()

            primitives.add(new Cesium.Primitive({
                geometryInstances : new Cesium.GeometryInstance({
                    geometry : new Cesium.PolylineGeometry({
                        positions : positions,
                        width : 1.0,
                        vertexFormat : Cesium.PolylineColorAppearance.VERTEX_FORMAT
                    }),
                    attributes: {
                        color: Cesium.ColorGeometryInstanceAttribute.fromColor(new Cesium.Color(0.8, 0.8, 0.8, 1))
                    }
                }),
                appearance : new Cesium.PolylineColorAppearance()
            }))

    load_cities()
    )


load_cities = ()->

    labels = new Cesium.LabelCollection()
    for city in cities
        coord = city['coordinates']
        name = city['name']
        labels.add({
            position : Cesium.Cartesian3.fromDegrees(coord[0], coord[1]),
            text     : "◉ "+name,
            font      : '12px Helvetica'
        });
    scene.primitives.add(labels);



#    CLICK HANDLER
handler = new Cesium.ScreenSpaceEventHandler(scene.canvas)
ellipsoid = scene.globe.ellipsoid

handler.setInputAction( ( (movement)->
    polygon = scene.drillPick(movement.position)[0]
    if (typeof polygon.id) == "string"
        polygon_name = polygon.id
    else
        polygon_name = polygon.id.properties.NAME_EN
    selected_polygon_name = polygon_name

    rect = get_oopt_rect(polygon_name)
    scene.camera.flyToRectangle({destination: rect})
    setTimeout(open_menu, 100)

), Cesium.ScreenSpaceEventType.LEFT_CLICK )


get_oopt_rect = (name)->

    _points = [];

    for polygon in oopt[name]
        _points = _points.concat( polygon.polygon.positions.getValue() )

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
        destination: Cesium.Cartesian3.fromDegrees(85, 60, 10000000.0),
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
)



#   MENU CLICK HANDLERS

$('.popup_menu .info').on('click', (e)->
    e.stopPropagation()
    open_info_popup()
)

$('.popup_menu .video').on('click', (e)->
    e.stopPropagation()
    open_video_popup()
)

$('.popup_menu .photo').on('click', (e)->
    e.stopPropagation()
    open_photo_popup()
)

$('.popup_menu .web').on('click', (e)->
    e.stopPropagation()
    open_web_popup()
)

open_menu = ()->
    $('.popup_menu').fadeIn(3000)


close_menu = ()->
    $('.popup_menu').fadeOut()
    $('.popup').fadeOut()

$(document).on('click', close_menu)

$('.popup_menu').hide()
$('.popup').hide()

open_info_popup = ()->
    $('.popup').fadeIn()
    $('.popup>div').hide()
    $('.popup .info').show()

open_video_popup = ()->
    $('.popup').fadeIn()
    $('.popup>div').hide()
    $('.popup .video').show()

open_photo_popup = ()->
    $('.popup').fadeIn()
    $('.popup>div').hide()
    $('.popup .photo').show()

open_web_popup = ()->
    $('.popup').fadeIn()
    $('.popup>div').hide()
    $('.popup .web').show()


showed_image = 0

$('.photos_left').on('click', (e)->
    e.stopPropagation()
    if showed_image!=0
        showed_image--
        $('.photo_container').transition({ x: -500*showed_image }, 300, 'ease');
)

$('.photos_right').on('click', (e)->
    e.stopPropagation()
    if showed_image!=4
        showed_image++
        $('.photo_container').transition({ x: -500*showed_image }, 300, 'ease');
)
























