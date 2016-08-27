#   SETTINGS

settings ={
    home: [147, 60, 6000000.0]
    baseMap_ru: "kosmo",
    baseMap_en: "kosmo",
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

#   NORTH ORIENTATION

to_north = ()->
    scene.camera.setView({
        orientation: {
            heading : 0.0,
            pitch : -Cesium.Math.PI_OVER_TWO,
            roll : 0.0
        }
    })

$(".to_north_btn").on("click", ()->
    to_north()
)

#    DATA LOADER
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

        build_events()
    )

build_events = ()->
    dataSource = new Cesium.GeoJsonDataSource()

    dataSource.load(settings.layerPath + "events.geojson").then( ()->      
        viewer.dataSources.add(dataSource);
        entities = dataSource.entities.values

        for entity in entities
            entity.billboard = undefined
            entity.point = new Cesium.PointGraphics({
                color: Cesium.Color.fromCssColorString('#30b2f1'),
                outlineColor: Cesium.Color.fromCssColorString('rgba(0,0,0,.7)'),
                outlineWidth: 6,
                pixelSize: 11
            })

    load_borders()
    )

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
        load_regions() 
    )

load_regions = ()->
    border_source = new Cesium.GeoJsonDataSource()
    border_source.load(settings.layerPath + 'regional_dv.topojson', {clampToGround: true}).then( ()->

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
    )


#  INFO BOX

add_info_box_data = (term, value)->
    $(".info-box__data").append("<div class='info-box__data__item'>\
        <span class='info-box__data__term'> " + term + ": </span>\
        <span class='info-box__data__value'>" + value + "</span>\
    </div>")

build_info_box = (data)->
    $(".info-box__title").text(data.descript)

    
    fotorama = $(".fotorama").data("fotorama")

    if (data.num_images==1) 
        $(".fotorama").addClass("fotorama--one-image")
    else
        $(".fotorama--one-image").removeClass("fotorama--one-image")

    dataImg = []
    for i in [1..data.num_images]
        dataImg.push( {img : settings.dataPath + "events/" + data.id + "/" + i + ".jpg"} )

    if (fotorama)
        fotorama.show( 0 )
        fotorama.load( dataImg )
    else
        $(".fotorama").fotorama({
            data: dataImg
        })
        fotorama = $(".fotorama").data("fotorama")

    $(".info-box__data").empty()
    if (data.status && (data.status!=""))
        add_info_box_data("Статус", data.status)
    if (data.rayon && (data.rayon!=""))
        add_info_box_data("Район", data.rayon)
    if (data.lat && data.lon && (data.lat!="") && (data.lon!=""))
        add_info_box_data("Координаты", data.lat + "°, " + data.lon + "°")



show_info_box = ()->   
    $("body").addClass("show-info")

hide_info_box = ()->
    $("body").removeClass("show-info")


#    CLICK HANDLER
handler = new Cesium.ScreenSpaceEventHandler(scene.canvas)
ellipsoid = scene.globe.ellipsoid

handler.setInputAction( ( (movement)->
    target = scene.pick(movement.position)
    if (target)
        if (target.id.point)
            build_info_box(target.id.properties)
            if (!$("body").hasClass("show-info"))
                show_info_box()
        else
            hide_info_box()
    else
        hide_info_box()
    
), Cesium.ScreenSpaceEventType.LEFT_CLICK )


$(".js-closeInfoBox").on("click", (e)->
    e.preventDefault()
    hide_info_box()
)

#    HOME BTN CLICK
$('.home_btn').on('click', ()->
    fly_to_home()
)
