基本用法

```vue
<template>
  <div>
    <el-button type="primary" size="mini" @click="select">选择</el-button>
      
      <p 
        :key="index" 
        v-for="(item,index) in selected"
      >
        id:{{item.id}}, name:{{item.name}}
      </p>
      
      <dialog-tree-checkbox
        :visible.sync="visible"
        title="选择数据"
        :selected="selected"
        :treeConfig="treeConfig"
        :checkboxConfig="checkboxConfig"
        @handSelect="handSelect"
      />
  </div>
</template>

<script>
export default {
  data() {
    return {
      visible: false,
      selected: [],
      treeConfig: {
        url: 'https://www.easy-mock.com/mock/5d257f37ef317e4c3423a0df/dialog-tree-checkbox/tree'
      },
      checkboxConfig: {
        url: 'https://www.easy-mock.com/mock/5d257f37ef317e4c3423a0df/dialog-tree-checkbox/checkbox'
      }
    }
  },
  methods: {
    select(){
      this.visible = true
    },
    handSelect(val){
      this.selected = val
    },
    getSelected(){
      let url = 'https://www.easy-mock.com/mock/5d257f37ef317e4c3423a0df/dialog-tree-checkbox/selected'
      this.$axios.get(url).then((res) => {
        this.selected = res.data.payload
      })
    }
  },
  created() {
    this.getSelected()
  }
}
</script>
```