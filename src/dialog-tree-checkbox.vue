<template>
  <el-dialog
    class="dialog-tree-checkbox"
    v-bind="Object.assign({}, theDialogConfig.dialogAttr, $attrs)"
    v-on="$listeners"
    @opened="dialogOpened"
  >

    <!--左侧-树形选择-->
    <div class="d-left">
      <el-tree
        ref="tree"
        node-key="id"
        :data="tree.data"
        :props="tree.props"
        show-checkbox
        :default-expanded-keys="tree.defaultExpandedKeys"
        @check="treeCheck"
      ></el-tree>
    </div>

    <!--右侧-checkbox选择-->
    <div class="d-right">
      <el-checkbox
        :indeterminate="checkbox.isIndeterminate"
        v-model="checkbox.checkAll"
        @change="handleCheckAllChange"
      >全选</el-checkbox
      >
      <el-checkbox-group
        v-model="checkbox.checkedKeys"
        @change="handleCheckedChange"
      >
        <el-checkbox
          v-for="item in checkbox.list"
          :label="item.id"
          :key="item.id"
        >
          <el-tooltip effect="dark" :content="item.name" placement="top">
            <span>{{ item.name }}</span>
          </el-tooltip>
        </el-checkbox>
      </el-checkbox-group>
    </div>

    <span slot="footer" class="dialog-footer">
      <span class="selected-current">选中{{ selectedDy.length }}个</span>

      <el-button size="mini" @click="close">取 消</el-button>
      <el-button size="mini" type="primary" @click="confirm">确 定</el-button>
    </span>
  </el-dialog>
</template>

<script>
import _ from 'lodash'
import {
  compareRow,
  findRowFromList,
  findSameRow,
  findNotIncludeRow,
  delList,
  isEmptyObject
} from './utils.js'
import {DIALOG_CONFIG_DEFAULT} from './config.js'
export default {
  name: 'DialogTreeCheckbox',
  inheritAttrs: false,
  props: {
    /** 弹框打开后执行 */
    opened: {type: Function, required: false, default: () => {}},
    /**  初始时选中数据 */
    selected: {type: Array, required: false, default: () => []},
    /** 弹框配置参数，具体格式见 ./config.js */
    dialogConfig: {type: Object, required: false, default: () => {}},
    /** 树形数组配置参数 */
    treeConfig: {type: Object, required: true, default: () => {}},
    /** checkbox配置参数 */
    checkboxConfig: {type: Object, required: true, default: () => {}}
  },
  data() {
    return {
      // 弹框配置
      theDialogConfig: Object.assign(
        {},
        DIALOG_CONFIG_DEFAULT,
        this.dialogConfig
      ),
      // 左侧树形数据
      tree: {
        // 是否请求过数据
        isRequested: false,
        props: {
          children: 'children',
          label: 'name'
        },
        defaultExpandedKeys: ['0'],
        data: [{id: '0', name: '全部', children: []}],
        // 点击选中node的key
        activeNodeKey: ''
      },
      // 右侧复选框数据
      checkbox: {
        // 是否请求过数据
        isRequested: false,
        checkAll: false,
        isIndeterminate: false,
        checkedKeys: [],
        checkedList: [],
        list: []
      },
      // 组件中选中的checkbox(所有分组中的选择)[动态]
      selectedDy: []
    }
  },
  methods: {
    init() {
      this.getTree()
      let checkedTreeKeys = _.uniq(_.map(this.selectedDy, 'categoryId'))
      this.getCheckbox(checkedTreeKeys, false)
    },
    // ----弹框相关方法-----------start------------------------
    /** 弹框打开后*/
    dialogOpened() {
      this.opened()
      this.init()
    },
    /** 关闭弹框*/
    close() {
      /** 关闭弹框*/
      this.$emit('update:visible', false)
    },
    /** 确定*/
    confirm() {
      /** 确定选择*/
      this.$emit('handSelect', this.selectedDy)
      this.close()
    },

    // ----左侧(树形模块)方法-----------start--------------------
    /** 获取树形数据(isRefresh:是否直接刷新数据)*/
    async getTree(isRefresh = false) {
      if (!isRefresh && this.tree.isRequested) {
        return
      }
      let {data} = await this.$axios.get(this.treeConfig.url)
      if (data.code != '0') {
        return
      }
      this.tree.data[0].children = data.payload.content
      this.setCheckedTree()
      this.tree.isRequested = true
    },
    /** 当复选框被点击的时候触发*/
    async treeCheck() {
      // 清空checkbox数据
      this.checkbox.list = []
      this.checkbox.checkAll = false
      this.checkbox.isIndeterminate = false

      let checkedNotChildKeys = this.$refs.tree.getCheckedKeys(true)
      await this.getCheckbox(checkedNotChildKeys, true)
    },
    /** tree-设置选中的tree*/
    setCheckedTree() {
      // 1.根据 在选中的数据(selectedDy)中找到所有选到的tree类型
      let checkedTreeKeys = _.uniq(_.map(this.selectedDy, 'categoryId'))
      this.$nextTick(() => {
        this.$refs.tree.setCheckedKeys(checkedTreeKeys)
      })
    },

    // ----右侧(树形模块)方法-----------start---------------------
    async getCheckbox(ids = [], isRefresh = false) {
      if (!isRefresh && this.checkbox.isRequested) {
        return
      }
      if (ids.length == 0) {
        return
      }
      let idsStr = ids.join(',')
      let {data} = await this.$axios.get(
        `${this.checkboxConfig.url}?categoryId=${idsStr}`
      )
      if (data.code != '0') {
        return
      }
      this.checkbox.list = data.payload.content
      this.setCheckedCheckbox()
      this.checkbox.isRequested = true
    },
    /** checkbox-group-当绑定值变化时触发的事件*/
    handleCheckAllChange(val) {
      this.checkbox.checkedKeys = val ? _.map(this.checkbox.list, 'id') : []
      this.checkbox.isIndeterminate = false
      this.setSelectedDy()
    },
    /** checkbox-当绑定值变化时触发的事件*/
    handleCheckedChange(value) {
      let checkedCount = value.length
      this.checkbox.checkAll = checkedCount === this.checkbox.list.length
      this.checkbox.isIndeterminate =
        checkedCount > 0 && checkedCount < this.checkbox.list.length
      this.setSelectedDy()
    },
    /** 设置组件中选择的数据selectedDy*/
    setSelectedDy() {
      // 当前选中的obj格式数据
      this.checkbox.checkedList = this.checkbox.list.reduce((res, cur) => {
        if (this.checkbox.checkedKeys.includes(cur.id)) {
          res.push(cur)
        }
        return res
      }, [])

      // 1.找出selected无，checkbox.checkList有的数据
      let addList = findNotIncludeRow(
        this.selectedDy,
        this.checkbox.checkedList
      )
      this.selectedDy = this.selectedDy.concat(addList)

      // 2.找出selected和checkbox.list，但checkbox.checkedList无的数据
      let sameData = findSameRow(this.selectedDy, this.checkbox.list)
      let delData = findNotIncludeRow(this.checkbox.checkedList, sameData)
      this.selectedDy = delList(this.selectedDy, delData)
    },
    /** checkbox-设置选中checkbox*/
    setCheckedCheckbox() {
      // 1.找出this.selected和this.checkbox.list都有，并存入checkbox.checkList中
      let addList = _.intersectionBy(this.selectedDy, this.checkbox.list, 'id')
      this.checkbox.checkedKeys = _.map(addList, 'id')
      this.handleCheckedChange(this.checkbox.checkedKeys)
    }
  },
  watch: {
    selected: {
      handler(val) {
        this.selectedDy = val
        this.setCheckedCheckbox()
      },
      deep: true,
      immediate: true
    }
  },
  created() {}
}
</script>

<style lang="stylus" scoped>
  /deep/ .el-dialog{
    .el-dialog__body {
      display: flex;
      justify-content: space-between;
      height: 60vh;
      overflow: auto;
    }
  }

  .d-left {
    width: 300px;
  }

  .d-right {
    width: calc(100% - 320px);

    .el-checkbox-group {
      .el-checkbox {
        width: 100px;
        margin: 10px 0 0 10px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }
    }
  }

  .dialog-footer {
    .selected-current {
      float: left;
    }
  }
</style>
