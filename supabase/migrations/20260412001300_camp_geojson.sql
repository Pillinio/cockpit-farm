-- Function to return camps as GeoJSON feature collection for Leaflet map
create or replace function get_camps_geojson()
returns json language sql stable security definer as $$
  select json_build_object(
    'type', 'FeatureCollection',
    'features', coalesce(json_agg(
      json_build_object(
        'type', 'Feature',
        'properties', json_build_object(
          'id', id,
          'name', name,
          'parent_camp', parent_camp,
          'area_ha', round(area_ha::numeric, 1),
          'purpose', purpose
        ),
        'geometry', extensions.ST_AsGeoJSON(geom)::json
      )
    ), '[]'::json)
  ) from farm_camps where active = true and geom is not null;
$$;
