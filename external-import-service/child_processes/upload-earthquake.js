const cron = require('node-cron');
const CovJSONReader = require('covjson-reader');
const turf = require('@turf/turf');
const moment = require('moment');
const axios = require('axios');

const fetchData = async () => {
  const url = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson';
  const { data } = await axios.get(url);

  const toSecUnixTimestamp = (timestamp) => Math.floor(timestamp / 1000);

  const toUnixTimestamp = (dateString, format) => moment(dateString, format).unix();
  const dateFormat = 'YYYY-MM-DDTHH:mm:ss.SSSZ';

  const received_at = Math.floor(new Date().getTime() / 1000);

  const processDetails = async (shakemapData) =>
    await Promise.all(
      shakemapData?.map(async (el) => {
        const coverage_mmi_high_url = el.contents['download/coverage_mmi_high_res.covjson']?.url;
        if (!coverage_mmi_high_url) return null;

        const { data: coverage_mmi_high_result } = await axios.get(coverage_mmi_high_url);
        if (!coverage_mmi_high_result) return null;

        const coverage_mmi_high_parsed = await CovJSONReader.read(coverage_mmi_high_result);
        const polygonData = definePolygonForCovJson(coverage_mmi_high_parsed);

        return {
          id: el.id,
          start: toUnixTimestamp(el.properties.eventtime, dateFormat),
          update_time: toSecUnixTimestamp(el.updateTime),
          ...polygonData,
        };
      })
    );

  const processGeoJSON = async (data) => {
    const features = data?.features
      .filter(
        (feature) =>
          feature?.properties?.types?.includes('shakemap') &&
          feature?.properties?.mag >= 4.5 &&
          feature?.properties?.mmi
      )
      .map(async (feature) => {
        const detailsUrl = feature.properties.detail;
        const { data: data_details } = await axios.get(detailsUrl);

        const shakemapData = data_details?.properties?.products?.shakemap || null;

        const shakemapDetails = shakemapData ? await processDetails(shakemapData) : null;

        if (!shakemapDetails || shakemapDetails.every((detail) => detail === null)) {
          return null;
        }

        return shakemapDetails
          .filter((shakemapDetail) => shakemapDetail !== null)
          .map((shakemapDetail) => ({
            ...shakemapDetail,
            feature_id: feature.id,
            received_at,
            source: 'USGS Earthquake Hazards Program',
            data_type: 'Earthquake MMI Shakemaps',
            country: 'NULL',
            state: 'NULL',
            place: feature.properties.place,
            title: feature.properties.title,
            net: feature.properties.net,
            issue_time: toSecUnixTimestamp(feature.properties.time),
            update_time:
              shakemapDetail.update_time ||
              toSecUnixTimestamp(feature.properties.updated || feature.properties.time),
            mag: feature.properties.mag,
            mmi: feature.properties.mmi,
            cdi: feature.properties.cdi,
            rms: feature.properties.rms,
            gap: feature.properties.gap,
            point: feature.geometry,
          }));
      });

    const result = await Promise.all(features);
    return result.flat().filter((item) => item !== null);
  };

  const earthquakes = (await processGeoJSON(data)) || [];
  if (!earthquakes || !earthquakes.length) {
    return null;
  }

  return await proceedDocuments(earthquakes);
};

const definePolygonForCovJson = (data) => {
  const { domain } = data._covjson;
  const xStart = domain.axes.x.start;
  const xStop = domain.axes.x.stop;
  const yStart = domain.axes.y.start;
  const yStop = domain.axes.y.stop;

  const bbox = [xStart, yStart, xStop, yStop];

  return {
    polygon: turf.bboxPolygon(bbox).geometry,
    x_axis: domain.axes.x,
    y_axis: domain.axes.y,
  };
};

const proceedDocuments = async (earthquakes) => {
  console.log('earthquakes:', earthquakes);
  // TODO: logic to upload documents to (?)
};

cron.schedule('15 * * * *', () => {
  console.log('Earthquake job running at', new Date());
  fetchData();
});

console.log('upload-earthquake process started');
