
/**
 *
 * gPodder QML UI Reference Implementation
 * Copyright (c) 2013, 2014, Thomas Perl <m@thp.io>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 *
 */

import QtQuick 2.0

import 'util.js' as Util
import 'constants.js' as Constants

ListModel {
    id: episodeListModel

    property var podcast_id: -1

    property var queries: ({
        All: '',
        Fresh: 'new or downloading',
        Downloaded: 'downloaded or downloading',
        UnplayedDownloads: 'downloaded and not played',
        FinishedDownloads: 'downloaded and finished',
        UnfinishedDownloads: 'downloaded and not finished',
        HideDeleted: 'not deleted',
        Deleted: 'deleted',
        ShortDownloads: 'downloaded and min > 0 and min < 10',
    })

    property var filters: ([
        { label: 'All', query: episodeListModel.queries.All },
        { label: 'Fresh', query: episodeListModel.queries.Fresh },
        { label: 'Downloaded', query: episodeListModel.queries.Downloaded },
        { label: 'Unplayed downloads', query: episodeListModel.queries.UnplayedDownloads },
        { label: 'Finished downloads', query: episodeListModel.queries.FinishedDownloads },
        { label: 'Unfinished downloads', query: episodeListModel.queries.UnfinishedDownloads },
        { label: 'Hide deleted', query: episodeListModel.queries.HideDeleted },
        { label: 'Deleted episodes', query: episodeListModel.queries.Deleted },
        { label: 'Short downloads (< 10 min)', query: episodeListModel.queries.ShortDownloads },
    ])

    property bool ready: false
    property int currentFilterIndex: -1
    property string currentCustomQuery: queries.All

    Component.onCompleted: {
        // Request filter, then load episodes
        py.call('main.get_config_value', ['ui.qml.episode_list.filter_eql'], function (result) {
            setQuery(result);
            reload();
        });
    }

    function setQueryIndex(index) {
        currentFilterIndex = index;
        py.call('main.set_config_value', ['ui.qml.episode_list.filter_eql', filters[currentFilterIndex].query]);
    }

    function setQuery(query) {
        for (var i=0; i<filters.length; i++) {
            if (filters[i].query === query) {
                py.call('main.set_config_value', ['ui.qml.episode_list.filter_eql', query]);
                currentFilterIndex = i;
                return;
            }
        }

        currentFilterIndex = -1;
        currentCustomQuery = query;

        py.call('main.set_config_value', ['ui.qml.episode_list.filter_eql', query]);
    }

    function loadAllEpisodes(callback) {
        episodeListModel.podcast_id = -1;
        reload(callback);
    }

    function loadEpisodes(podcast_id, callback) {
        episodeListModel.podcast_id = podcast_id;
        reload(callback);
    }

    function reload(callback) {
        var query;

        if (currentFilterIndex !== -1) {
            query = filters[currentFilterIndex].query;
        } else {
            query = currentCustomQuery;
        }

        ready = false;
        py.call('main.load_episodes', [podcast_id, query], function (episodes) {
            Util.updateModelFrom(episodeListModel, episodes);
            episodeListModel.ready = true;
            if (callback !== undefined) {
                callback();
            }
        });
    }
}
